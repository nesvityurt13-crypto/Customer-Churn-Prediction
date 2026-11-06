-- Загрузка CSV и проверки качества данных.
-- Запускать из корня репозитория, чтобы относительный путь к файлу был корректным:
-- psql -U churn_user -d churn_db -f sql/02_load_and_check_data.sql

\set ON_ERROR_STOP on

TRUNCATE TABLE telco_churn;

-- В исходном CSV пустые TotalCharges записаны как пробел, поэтому NULL ' '.
\copy telco_churn (customer_id, gender, senior_citizen, partner, dependents, tenure, phone_service, multiple_lines, internet_service, online_security, online_backup, device_protection, tech_support, streaming_tv, streaming_movies, contract, paperless_billing, payment_method, monthly_charges, total_charges, churn) FROM 'data/raw/WA_Fn-UseC_-Telco-Customer-Churn.csv' WITH (FORMAT csv, HEADER true, NULL ' ');

-- 1. Сколько строк загрузилось
SELECT COUNT(*) AS rows_loaded
FROM telco_churn;

-- 2. Уникальность клиентов
SELECT COUNT(DISTINCT customer_id) AS distinct_customers
FROM telco_churn;

-- 3. Распределение целевой переменной
SELECT
    churn,
    COUNT(*) AS customers,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS share_pct
FROM telco_churn
GROUP BY churn
ORDER BY churn;

-- 4. Пустые TotalCharges: ожидаем 11 строк, все с tenure = 0
SELECT COUNT(*) AS null_total_charges
FROM telco_churn
WHERE total_charges IS NULL;

SELECT COUNT(*) AS null_total_charges_with_positive_tenure
FROM telco_churn
WHERE total_charges IS NULL AND tenure > 0;

-- 5. Дубликаты customerID: ожидаем 0
SELECT COUNT(*) AS duplicate_customer_ids
FROM (
    SELECT customer_id
    FROM telco_churn
    GROUP BY customer_id
    HAVING COUNT(*) > 1
) duplicates;
