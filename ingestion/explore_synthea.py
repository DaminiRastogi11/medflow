"""
Quick exploration of Synthea CSV files.
Prints row counts, columns, and a sample row for each file.
Run with: uv run python ingestion/explore_synthea.py
"""

import os
from pathlib import Path
import pandas as pd
from dotenv import load_dotenv

load_dotenv()

DATA_PATH = Path(os.getenv("SYNTHEA_DATA_PATH", "./data/raw/synthea"))


def explore():
    print(f"\n{'='*70}")
    print(f"SYNTHEA DATA EXPLORATION — {DATA_PATH.resolve()}")
    print(f"{'='*70}\n")

    csv_files = sorted(DATA_PATH.glob("*.csv"))

    if not csv_files:
        print(f" No CSV files found in {DATA_PATH}")
        print("   Check that you've extracted the Synthea sample data correctly.")
        return

    summary = []
    for csv_file in csv_files:
        try:
            df = pd.read_csv(csv_file, low_memory=False)
            summary.append({
                "file": csv_file.name,
                "rows": len(df),
                "columns": len(df.columns),
                "size_mb": round(csv_file.stat().st_size / 1024 / 1024, 2),
            })
            print(f" {csv_file.name}")
            print(f"   Rows: {len(df):,}")
            print(f"   Columns ({len(df.columns)}): {', '.join(df.columns[:8].tolist())}{'...' if len(df.columns) > 8 else ''}")
            print(f"   Size: {round(csv_file.stat().st_size / 1024 / 1024, 2)} MB")
            print()
        except Exception as e:
            print(f" Error reading {csv_file.name}: {e}\n")

    print(f"{'='*70}")
    print(f"TOTAL: {len(summary)} files, "
          f"{sum(s['rows'] for s in summary):,} rows, "
          f"{round(sum(s['size_mb'] for s in summary), 2)} MB")
    print(f"{'='*70}\n")


if __name__ == "__main__":
    explore()