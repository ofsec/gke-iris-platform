import os
import time
from contextlib import asynccontextmanager

import google.auth
import joblib
from fastapi import FastAPI, HTTPException, Request
from google.auth.transport.requests import AuthorizedSession
from google.cloud import storage
from prometheus_client import CONTENT_TYPE_LATEST, Counter, Histogram, generate_latest
from pydantic import BaseModel
from starlette.responses import Response

PROJECT = os.environ["PROJECT_ID"]
REGION = os.environ.get("REGION", "europe-west1")
MODEL_NAME = os.environ.get("MODEL_NAME", "iris-classifier")
SPECIES = ["setosa", "versicolor", "virginica"]
state = {}

# Golden signals: traffic and errors (counter by status), latency (histogram).
# "path" is the route template, never the raw URL, to keep label cardinality bounded.
REQUESTS = Counter("http_requests_total", "HTTP requests", ["method", "path", "status"])
LATENCY = Histogram(
    "http_request_duration_seconds", "HTTP request latency", ["method", "path"],
    buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5),
)
# Business metric: what the model answers
PREDICTIONS = Counter("iris_predictions_total", "Predictions returned, by species", ["species"])


def find_latest_model():
    """Ask the Model Registry for every model with our name, keep the newest."""
    creds, _ = google.auth.default(scopes=["https://www.googleapis.com/auth/cloud-platform"])
    session = AuthorizedSession(creds)
    url = f"https://{REGION}-aiplatform.googleapis.com/v1/projects/{PROJECT}/locations/{REGION}/models"
    resp = session.get(url, params={"filter": f'display_name="{MODEL_NAME}"'})
    resp.raise_for_status()
    models = resp.json().get("models", [])
    if not models:
        raise RuntimeError(f"No model named {MODEL_NAME} in the registry")
    newest = max(models, key=lambda m: m["createTime"])
    return newest["name"], newest["artifactUri"]


def download_model(artifact_uri):
    """Download model.joblib from the model's folder in Cloud Storage."""
    bucket_name, _, prefix = artifact_uri.removeprefix("gs://").partition("/")
    local_path = "/tmp/model.joblib"
    storage.Client(project=PROJECT).bucket(bucket_name).blob(f"{prefix}/model.joblib").download_to_filename(local_path)
    return joblib.load(local_path)


@asynccontextmanager
async def lifespan(app):
    name, uri = find_latest_model()
    state["model"] = download_model(uri)
    state["model_name"] = name
    print(f"Loaded {name} from {uri}", flush=True)
    yield


app = FastAPI(lifespan=lifespan)


@app.middleware("http")
async def record_metrics(request: Request, call_next):
    start = time.perf_counter()
    status = 500  # an unhandled exception still counts as an error
    try:
        response = await call_next(request)
        status = response.status_code
        return response
    finally:
        route = request.scope.get("route")
        path = route.path if route else "unmatched"
        if path != "/metrics":  # don't measure the scrapes themselves
            REQUESTS.labels(request.method, path, str(status)).inc()
            LATENCY.labels(request.method, path).observe(time.perf_counter() - start)


@app.get("/metrics")
def metrics():
    return Response(generate_latest(), media_type=CONTENT_TYPE_LATEST)


class PredictRequest(BaseModel):
    instances: list[list[float]]  # each: sepal length, sepal width, petal length, petal width (cm)


@app.get("/healthz")
def healthz():
    return {"status": "ok", "model": state.get("model_name")}


@app.post("/predict")
def predict(req: PredictRequest):
    if any(len(x) != 4 for x in req.instances):
        raise HTTPException(status_code=422, detail="Each instance needs exactly 4 measurements")
    classes = state["model"].predict(req.instances)
    for c in classes:
        PREDICTIONS.labels(SPECIES[int(c)]).inc()
    return {
        "model": state["model_name"],
        "predictions": [{"class": int(c), "species": SPECIES[int(c)]} for c in classes],
    }
