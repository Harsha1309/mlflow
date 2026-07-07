"""
Train stage: trains a RandomForestRegressor on the prepared training
set and logs params/metrics/model to MLflow (running on your EKS
MLflow deployment). Also writes a local metrics.json so DVC can track
metrics without needing to hit the MLflow server.
"""
import os
import json
import yaml
import mlflow
import mlflow.sklearn
from mlflow.tracking import MlflowClient
import pandas as pd
from pathlib import Path
from sklearn.ensemble import RandomForestRegressor
from sklearn.metrics import mean_squared_error, mean_absolute_error, r2_score

PREPARED_DIR = Path("data/prepared")
MODEL_DIR = Path("model")
TARGET_COL = "quality"


def load_params():
    with open("params.yaml") as f:
        return yaml.safe_load(f)


def main():
    params = load_params()
    train_params = params["train"]
    mlflow_params = params["mlflow"]

    MODEL_DIR.mkdir(parents=True, exist_ok=True)

    train_df = pd.read_csv(PREPARED_DIR / "train.csv")
    test_df = pd.read_csv(PREPARED_DIR / "test.csv")

    X_train = train_df.drop(columns=[TARGET_COL])
    y_train = train_df[TARGET_COL]
    X_test = test_df.drop(columns=[TARGET_COL])
    y_test = test_df[TARGET_COL]

    # MLFLOW_TRACKING_URI env var (set in CI/CD or shell) takes priority
    # over params.yaml, so the same code works locally and in the cluster.
    tracking_uri = os.environ.get("MLFLOW_TRACKING_URI", mlflow_params["tracking_uri"])
    mlflow.set_tracking_uri(tracking_uri)
    client = MlflowClient(tracking_uri=tracking_uri)

    # Use a new experiment name to avoid old experiments with stale artifact locations.
    exp_name = f"{mlflow_params['experiment_name']}-current"
    experiment = client.get_experiment_by_name(exp_name)
    if experiment is None:
        experiment_id = client.create_experiment(exp_name)
    else:
        experiment_id = experiment.experiment_id
    mlflow.set_experiment(experiment_id)

    with mlflow.start_run() as run:
        model = RandomForestRegressor(
            n_estimators=train_params["n_estimators"],
            max_depth=train_params["max_depth"],
            min_samples_leaf=train_params["min_samples_leaf"],
            random_state=train_params["random_state"],
        )
        model.fit(X_train, y_train)

        preds = model.predict(X_test)
        metrics = {
            "rmse": mean_squared_error(y_test, preds) ** 0.5,
            "mae": mean_absolute_error(y_test, preds),
            "r2": r2_score(y_test, preds),
        }

        # Log to MLflow
        mlflow.log_params(train_params)
        mlflow.log_metrics(metrics)
        mlflow.sklearn.log_model(model, artifact_path="model")

        # Tag the run with git/DVC context so it's traceable back to a commit
        mlflow.set_tag("dvc_stage", "train")
        if "DVC_EXP_NAME" in os.environ:
            mlflow.set_tag("dvc_exp_name", os.environ["DVC_EXP_NAME"])

        print(f"MLflow run_id: {run.info.run_id}")
        print(f"Metrics: {metrics}")

        # Also persist locally so `dvc metrics show` / `dvc plots` work
        # without needing network access to MLflow.
        with open("metrics.json", "w") as f:
            json.dump(metrics, f, indent=2)

        with open(MODEL_DIR / "run_id.txt", "w") as f:
            f.write(run.info.run_id)


if __name__ == "__main__":
    main()
