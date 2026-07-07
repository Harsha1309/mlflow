"""
Evaluate stage: reloads the trained model, generates a predicted-vs-actual
plot, and logs it as an MLflow artifact on the same run used for training.
"""
import json
import mlflow
import mlflow.sklearn
import pandas as pd
import matplotlib.pyplot as plt
from pathlib import Path

PREPARED_DIR = Path("data/prepared")
MODEL_DIR = Path("model")
TARGET_COL = "quality"


def main():
    with open(MODEL_DIR / "run_id.txt") as f:
        run_id = f.read().strip()

    test_df = pd.read_csv(PREPARED_DIR / "test.csv")
    X_test = test_df.drop(columns=[TARGET_COL])
    y_test = test_df[TARGET_COL]

    model = mlflow.sklearn.load_model(f"runs:/{run_id}/model")
    preds = model.predict(X_test)

    fig, ax = plt.subplots(figsize=(6, 6))
    ax.scatter(y_test, preds, alpha=0.4)
    lims = [min(y_test.min(), preds.min()), max(y_test.max(), preds.max())]
    ax.plot(lims, lims, "r--", linewidth=1)
    ax.set_xlabel("Actual quality")
    ax.set_ylabel("Predicted quality")
    ax.set_title("Predicted vs Actual")

    plot_path = Path("eval_plot.png")
    fig.savefig(plot_path, dpi=120, bbox_inches="tight")

    with mlflow.start_run(run_id=run_id):
        mlflow.log_artifact(str(plot_path))

    print(f"Logged evaluation plot to MLflow run {run_id}")


if __name__ == "__main__":
    main()
