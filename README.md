# Customer Churn Prediction

Учебный проект по прогнозированию оттока клиентов телекоммуникационной компании. Цель — показать полный цикл работы с данными: первичное исследование, EDA, SQL-анализ в PostgreSQL, подготовку признаков, обучение и сравнение моделей, выбор порога и бизнес-интерпретацию.

Данные: [IBM Telco Customer Churn](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) (7 043 клиента, 21 столбец).

## Бизнес-задача

Компании важно заранее находить клиентов с повышенным риском ухода, чтобы отдел удержания мог приоритизировать контакты. В проекте решается задача бинарной классификации:

- `Churn = Yes` — клиент ушёл;
- `Churn = No` — клиент остался.

Доля оттока в данных — **26,54%** (1 869 из 7 043).

## Стек

- Python 3.13, Jupyter Notebook
- NumPy, pandas
- Matplotlib, Seaborn
- scikit-learn
- PostgreSQL 17 (Docker), pgAdmin 4
- Git, GitHub

## Структура проекта

```text
Customer-Churn-Prediction/
├── data/                         # создаётся локально, не публикуется
│   ├── raw/                      # исходный CSV
│   └── processed/                # train/test после подготовки
├── models/                       # сохранённая модель, не публикуется
├── notebooks/
│   ├── 01_data_overview.ipynb
│   ├── 02_eda.ipynb
│   ├── 03_feature_engineering.ipynb
│   ├── 04_model_training_evaluation.ipynb
│   ├── 05_model_robustness.ipynb
│   └── 06_calibration_and_thresholds.ipynb
├── sql/
│   ├── 01_create_tables.sql
│   ├── 02_load_and_check_data.sql
│   └── 03_business_analysis.sql
├── reports/
│   ├── project_conclusions.md
│   ├── cv_metrics.csv
│   ├── model_metrics.csv
│   ├── repeated_cv_metrics.csv
│   ├── permutation_importance.csv
│   ├── default_feature_importance.csv
│   ├── threshold_sensitivity.csv
│   ├── calibration_metrics.csv
│   ├── cost_sensitive_thresholds.csv
│   └── sql_results.txt
├── requirements.txt
└── README.md
```

## Этапы работы

1. **Первичное исследование** — структура данных, типы, пропуски, дубликаты, баланс классов.
2. **EDA** — распределения, связь признаков с оттоком, проверка четырёх гипотез.
3. **SQL-анализ** — загрузка данных в PostgreSQL и 11 аналитических запросов по сегментам.
4. **Подготовка признаков** — очистка, стратифицированное разбиение 80/20, `ColumnTransformer` и One-Hot Encoding внутри `Pipeline`.
5. **Моделирование** — Logistic Regression, Decision Tree, Random Forest, `GridSearchCV` (5-fold, scoring = PR-AUC).
6. **Оценка** — выбор порога по out-of-fold предсказаниям, метрики и матрица ошибок на тесте, ROC- и PR-кривые, важность признаков.
7. **Проверка устойчивости** — повторная кросс-валидация 5×3, permutation importance и чувствительность метрик к порогу.
8. **Калибровка и стоимость ошибок** — проверка вероятностей, сравнение sigmoid и isotonic, порог при разных отношениях стоимости FN/FP.
9. **Бизнес-выводы** — группа высокого риска, распределение по договорам, условная сумма ежемесячных платежей под риском.

## Основные результаты

### EDA и SQL

- Помесячный договор — **42,71%** оттока, годовой — **11,27%**, двухлетний — **2,83%**.
- Стаж 0–12 месяцев — **47,44%** оттока, 49–72 месяца — **9,51%**.
- `Electronic check` — **45,29%**, остальные способы оплаты — **15,24–19,11%**.
- Fiber optic — **41,89%**, DSL — **18,96%**, без интернета — **7,40%**.
- Без техподдержки (среди клиентов с интернетом) — **41,64%**, с поддержкой — **15,17%**.
- Сегмент «Month-to-month + Electronic check» — **53,73%** оттока и **77 315,60** ежемесячных платежей ушедших клиентов.

### Сравнение моделей

Кросс-валидация, 5-fold, scoring = PR-AUC:

| Модель | CV ROC-AUC | CV PR-AUC | CV Precision | CV Recall | CV F1 |
|---|---:|---:|---:|---:|---:|
| Logistic Regression | 0,8461 | 0,6615 | 0,6530 | 0,5445 | 0,5932 |
| Decision Tree | 0,8167 | 0,6201 | 0,5058 | 0,7793 | 0,6131 |
| **Random Forest** | **0,8474** | **0,6629** | 0,6718 | 0,5043 | 0,5757 |

Выбрана **Random Forest** (`n_estimators=200`, `max_depth=10`, `min_samples_leaf=10`). Logistic Regression отстаёт незначительно (PR-AUC 0,6615 против 0,6629) и выигрывает в интерпретируемости — для реального внедрения этот компромисс стоит обсудить отдельно.

### Финальная модель на тесте

Порог **0,2781** выбран по out-of-fold предсказаниям при требовании Recall ≥ 0,80. Тестовая выборка не использовалась для подбора порога.

| Метрика | Значение |
|---|---:|
| Accuracy | 0,7495 |
| Precision | 0,5183 |
| Recall | 0,7941 |
| F1-score | 0,6272 |
| ROC-AUC | 0,8425 |
| PR-AUC | 0,6548 |

Матрица ошибок: TN = 759, FP = 276, FN = 77, TP = 297.

При стандартном пороге 0,5 Precision выше (0,6644), но Recall падает до 0,5187. Выбор порога — управленческий компромисс между стоимостью пропущенного клиента и стоимостью лишнего контакта.

### Устойчивость и интерпретация

Повторная кросс-валидация 5×3 даёт PR-AUC **0,6649 ± 0,0212** и ROC-AUC **0,8486 ± 0,0115**. Результат близок к одиночной 5-fold. Разброс PR-AUC около 0,02 означает, что небольшое преимущество Random Forest над Logistic Regression может находиться в пределах случайной вариации.

Permutation importance на тесте выделяет `tenure`, `Contract`, `TotalCharges`, `InternetService`, `TechSupport` и `OnlineSecurity`. Встроенная важность Random Forest показывает ту же картину, но на уровне отдельных one-hot категорий. Расхождения по `MonthlyCharges` объясняются корреляцией с `TotalCharges`.

Чувствительность к порогу (OOF): при 0,2781 Precision — 0,5235, Recall — 0,7987, F1 — 0,6324; при 0,5 — Precision 0,6708, Recall 0,5043. Диапазон 0,25–0,30 — компромисс в пользу полноты. Подробнее — в `notebooks/05_model_robustness.ipynb`.

### Калибровка и стоимость ошибок

Random Forest уже даёт достаточно калиброванные вероятности: Brier score **0,1364**, log loss **0,4190**. Sigmoid и isotonic почти не меняют ROC-AUC и PR-AUC; isotonic немного улучшает Brier score до **0,1361** и log loss до **0,4186**, но выигрыш минимален.

Оптимальный порог зависит от отношения стоимости FN/FP: при 1 — **0,46**, при 2 — **0,34**, при 5 — **0,17**, при 10 — **0,08**. Порог 0,2781 соответствует отношению между 2 и 5. При очень высоких отношениях модель отмечает около 77% клиентов, что может быть неприменимо на практике. Это анализ чувствительности, а не расчёт ROI. Подробнее — в `notebooks/06_calibration_and_thresholds.ipynb`.

### Бизнес-интерпретация

- Модель отметила **573 клиента (40,7% теста)** как группу высокого риска.
- Среди них реально ушли **51,8%**; модель поймала **297 из 374** ушедших.
- Ежемесячные платежи группы риска — около **42 234**.
- Топ-10% по вероятности оттока (140 клиентов) дают **77,1%** фактического оттока при платежах около **11 310** в месяц.

Это оценка суммы под риском в рамках имеющегося среза, а не гарантированная потеря выручки и не расчёт ROI.

## Как воспроизвести

### 1. Клонировать репозиторий и создать окружение

```powershell
git clone https://github.com/nesvityurt13-crypto/Customer-Churn-Prediction.git
cd Customer-Churn-Prediction

python -m venv .venv
.\.venv\Scripts\Activate.ps1
pip install -r requirements.txt
```

### 2. Скачать данные

Скачать `WA_Fn-UseC_-Telco-Customer-Churn.csv` с [Kaggle](https://www.kaggle.com/datasets/blastchar/telco-customer-churn) и положить в `data/raw/` (папку создайте, если её нет). Файлы данных не хранятся в репозитории.

### 3. Запустить ноутбуки

Ноутбуки выполняются по порядку: `01` → `02` → `03` → `04` → `05` → `06`. Ноутбук `03` сохраняет обработанные данные в `data/processed/`, ноутбук `04` — модель в `models/churn_model.joblib`, ноутбуки `05` и `06` используют её для проверки устойчивости, интерпретации, калибровки и выбора порога.

Если нужен отдельный Jupyter kernel:

```powershell
python -m ipykernel install --user --name churn-venv --display-name ".venv (3.13)"
```

Запуск из командной строки:

```powershell
python -m jupyter nbconvert --to notebook --execute --inplace notebooks\01_data_overview.ipynb notebooks\02_eda.ipynb notebooks\03_feature_engineering.ipynb notebooks\04_model_training_evaluation.ipynb notebooks\05_model_robustness.ipynb notebooks\06_calibration_and_thresholds.ipynb --ExecutePreprocessor.kernel_name=churn-venv --ExecutePreprocessor.timeout=1800
```

### 4. SQL-анализ в PostgreSQL

Запустить контейнер (пароль демонстрационный, замените его при необходимости):

```powershell
docker run --name churn-postgres `
  -e POSTGRES_USER=churn_user `
  -e POSTGRES_PASSWORD=churn_password `
  -e POSTGRES_DB=churn_db `
  -p 5433:5432 `
  -v "${PWD}:/project" `
  -w /project `
  -d postgres:17
```

Выполнить SQL-файлы по порядку:

```powershell
docker exec churn-postgres psql -U churn_user -d churn_db -f sql/01_create_tables.sql
docker exec churn-postgres psql -U churn_user -d churn_db -f sql/02_load_and_check_data.sql
docker exec churn-postgres psql -U churn_user -d churn_db -f sql/03_business_analysis.sql
```

Подключение в pgAdmin 4: host `localhost`, port `5433`, database `churn_db`, user `churn_user`.

## Ограничения

- Данные демонстрационные, один срез без временной истории.
- Использовано одно разбиение train/test; при другом `random_state` метрики немного изменятся.
- Нет стоимости контакта, скидки и фактической эффективности удержания, поэтому реальный ROI не рассчитывается.
- Важность признаков не доказывает причинно-следственную связь; permutation importance может быть нестабильной при коррелированных признаках.
- Порог Recall ≥ 0,80 — учебное допущение, а не бизнес-требование.
- Стоимости ошибок в анализе порога гипотетические: реальных цен контакта и удержания в данных нет.

Подробные выводы, интерпретация и рекомендации — в [reports/project_conclusions.md](reports/project_conclusions.md).
