from pathlib import Path

import pandas as pd
from scipy.stats import spearmanr


# ============================================================
# Paths
# ============================================================

PROJECT_ROOT = Path(__file__).resolve().parents[1]

INPUT_PATH = PROJECT_ROOT / "data" / "py" / "mart_seller_correlation.csv"
OUTPUT_PATH = PROJECT_ROOT / "data" / "py" / "spearman_result.csv"


def main() -> None:

    # ============================================================
    # Load data
    # ============================================================

    df = pd.read_csv(INPUT_PATH)

    required_columns = {
        "seller_id",
        "late_delivery_rate",
        "avg_review_score",
    }

    missing_columns = required_columns.difference(df.columns)

    if missing_columns:
        raise ValueError(
            f"Missing columns: {sorted(missing_columns)}"
        )

    if df.empty:
        raise ValueError(
            "Correlation input contains no rows."
        )

    if df["seller_id"].duplicated().any():
        raise ValueError(
            "Correlation input contains duplicate seller_id values."
        )

    analytical_columns = [
        "late_delivery_rate",
        "avg_review_score",
    ]

    if df[analytical_columns].isna().any().any():
        raise ValueError(
            "Correlation input contains NULL analytical metrics."
        )

    # ============================================================
    # Spearman correlation
    # ============================================================

    rho, p_value = spearmanr(
        df["late_delivery_rate"],
        df["avg_review_score"],
    )

    # ============================================================
    # Save result
    # ============================================================

    result = pd.DataFrame(
        {
            "eligible_sellers": [len(df)],
            "spearman_rho": [rho],
            "p_value": [p_value],
        }
    )

    result.to_csv(
        OUTPUT_PATH,
        index=False,
    )

    # ============================================================
    # Console output
    # ============================================================

    print(f"eligible_sellers: {len(df)}")
    print(f"spearman_rho: {rho:.6f}")
    print(f"p_value: {p_value:.6g}")
    print(f"result_saved_to: {OUTPUT_PATH}")


if __name__ == "__main__":
    main()
