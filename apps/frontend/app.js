const ids = ["sl", "sw", "pl", "pw"];
  document.querySelectorAll(".sample").forEach(b => b.addEventListener("click", () => {
    b.dataset.v.split(",").forEach((v, i) => document.getElementById(ids[i]).value = v);
  }));
  document.getElementById("form").addEventListener("submit", async e => {
    e.preventDefault();
    const instance = ids.map(id => parseFloat(document.getElementById(id).value));
    const species = document.getElementById("species"), model = document.getElementById("model");
    species.textContent = "Classifying…"; model.textContent = "";
    try {
      const r = await fetch("/predict", { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ instances: [instance] }) });
      if (!r.ok) throw new Error(`Backend answered ${r.status}`);
      const data = await r.json();
      species.textContent = data.predictions[0].species;
      model.textContent = `Model: ${data.model}`;
    } catch (err) {
      species.textContent = "Prediction failed";
      model.textContent = err.message;
    }
  });
