"""
Prepare stage: loads the raw wine-quality dataset, cleans it, and
splits it into train/test sets. Outputs are tracked by DVC as pipeline
outputs (see dvc.yaml) so downstream stages depend on exact versions.
"""
import sys
import yaml
import pandas as pd
from pathlib import Path
from sklearn.model_selection import train_test_split

RAW_DATA_PATH = Path("data/raw/winequality-red.csv")
OUT_DIR = Path("data/prepared")


def load_params():
    with open("params.yaml") as f:
        return yaml.safe_load(f)["prepare"]


def main():
    params = load_params()
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    if not RAW_DATA_PATH.exists():
        print(f"ERROR: raw data not found at {RAW_DATA_PATH}", file=sys.stderr)
        print("Run `dvc pull` or place the dataset there, then `dvc add data/raw/winequality-red.csv`.",
              file=sys.stderr)
        sys.exit(1)

    df = pd.read_csv(RAW_DATA_PATH, sep=";")

    # basic cleaning: drop exact duplicate rows, drop any nulls
    before = len(df)
    df = df.drop_duplicates().dropna()
    print(f"Dropped {before - len(df)} duplicate/null rows")

    train_df, test_df = train_test_split(
        df,
        test_size=params["test_size"],
        random_state=params["random_state"],
    )

    train_df.to_csv(OUT_DIR / "train.csv", index=False)
    test_df.to_csv(OUT_DIR / "test.csv", index=False)

    print(f"Train rows: {len(train_df)}, Test rows: {len(test_df)}")


if __name__ == "__main__":
    main()
