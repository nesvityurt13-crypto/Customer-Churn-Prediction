"""Скоринг новых клиентов обученной моделью оттока."""

from argparse import ArgumentParser
from pathlib import Path

import joblib
import pandas as pd

PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_MODEL_PATH = PROJECT_ROOT / "models" / "churn_model.joblib"
DEFAULT_OUTPUT_PATH = PROJECT_ROOT / "reports" / "churn_predictions.csv"

FEATURES = [
    "gender",
    "SeniorCitizen",
    "Partner",
    "Dependents",
    "tenure",
    "PhoneService",
    "MultipleLines",
    "InternetService",
    "OnlineSecurity",
    "OnlineBackup",
    "DeviceProtection",
    "TechSupport",
    "StreamingTV",
    "StreamingMovies",
    "Contract",
    "PaperlessBilling",
    "PaymentMethod",
    "MonthlyCharges",
    "TotalCharges",
]


def parse_args():
    parser = ArgumentParser(
        description="Predict churn probability for customers from a CSV file."
    )
    parser.add_argument("input", type=Path, help="CSV с признаками клиентов.")
    parser.add_argument(
        "--model",
        type=Path,
        default=DEFAULT_MODEL_PATH,
        help="Путь к обученной модели.",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help="Путь для сохранения предсказаний.",
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=0.2781,
        help="Порог вероятности для отнесения клиента к группе риска.",
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if not 0 < args.threshold < 1:
        raise SystemExit("Порог должен быть между 0 и 1.")
    if not args.input.exists():
        raise SystemExit(f"Файл не найден: {args.input}")
    if not args.model.exists():
        raise SystemExit(f"Модель не найдена: {args.model}")

    data = pd.read_csv(args.input)
    missing_features = [column for column in FEATURES if column not in data.columns]
    if missing_features:
        raise SystemExit(
            "В файле нет обязательных колонок: " + ", ".join(missing_features)
        )

    model = joblib.load(args.model)
    probabilities = model.predict_proba(data[FEATURES])[:, 1]

    predictions = pd.DataFrame(
        {
            "churn_probability": probabilities.round(4),
            "predicted_churn": (probabilities >= args.threshold).astype(int),
        }
    )
    if "customerID" in data.columns:
        predictions.insert(0, "customerID", data["customerID"])

    args.output.parent.mkdir(parents=True, exist_ok=True)
    predictions.to_csv(args.output, index=False)

    print(f"Обработано клиентов: {len(predictions)}")
    print(f"Отмечено как риск: {int(predictions['predicted_churn'].sum())}")
    print(f"Результат сохранён: {args.output}")


if __name__ == "__main__":
    main()
