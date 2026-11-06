-- Аналитические запросы по клиентской базе.
-- Запуск: psql -U churn_user -d churn_db -f sql/03_business_analysis.sql

-- 1. Общая доля оттока
SELECT
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn;

-- 2. Отток по типу договора
SELECT
    contract,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM telco_churn
GROUP BY contract
ORDER BY churn_rate_pct DESC;

-- 3. Отток по группам стажа
SELECT
    CASE
        WHEN tenure <= 12 THEN '0-12'
        WHEN tenure <= 24 THEN '13-24'
        WHEN tenure <= 48 THEN '25-48'
        ELSE '49-72'
    END AS tenure_group,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY tenure_group
ORDER BY MIN(tenure);

-- 4. Отток по способу оплаты
SELECT
    payment_method,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges
FROM telco_churn
GROUP BY payment_method
ORDER BY churn_rate_pct DESC;

-- 5. Отток по типу интернета
SELECT
    internet_service,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY internet_service
ORDER BY churn_rate_pct DESC;

-- 6. Техподдержка только среди клиентов с интернетом
SELECT
    tech_support,
    COUNT(*) AS customers,
    COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
    ROUND(100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*), 2) AS churn_rate_pct
FROM telco_churn
WHERE internet_service <> 'No'
GROUP BY tech_support
ORDER BY churn_rate_pct DESC;

-- 7. Средние показатели ушедших и оставшихся клиентов
SELECT
    churn,
    COUNT(*) AS customers,
    ROUND(AVG(tenure), 1) AS avg_tenure,
    ROUND(AVG(monthly_charges), 2) AS avg_monthly_charges,
    ROUND(AVG(COALESCE(total_charges, 0)), 2) AS avg_total_charges
FROM telco_churn
GROUP BY churn
ORDER BY churn;

-- 8. Сегменты договор + способ оплаты с высокой долей оттока
WITH segments AS (
    SELECT
        contract,
        payment_method,
        COUNT(*) AS customers,
        COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
        100.0 * COUNT(*) FILTER (WHERE churn = 'Yes') / COUNT(*) AS churn_rate_pct,
        AVG(monthly_charges) AS avg_monthly_charges,
        SUM(monthly_charges) FILTER (WHERE churn = 'Yes') AS monthly_revenue_lost
    FROM telco_churn
    GROUP BY contract, payment_method
)
SELECT
    contract,
    payment_method,
    customers,
    churned_customers,
    ROUND(churn_rate_pct, 2) AS churn_rate_pct,
    ROUND(avg_monthly_charges, 2) AS avg_monthly_charges,
    ROUND(monthly_revenue_lost, 2) AS monthly_revenue_lost
FROM segments
WHERE customers >= 50
ORDER BY churn_rate_pct DESC, monthly_revenue_lost DESC
LIMIT 10;

-- 9. Сегменты с долей оттока выше 30% и не менее 100 клиентов (HAVING)
SELECT
    contract,
    payment_method,
    COUNT(*) AS customers,
    ROUND(100.0 * AVG(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END), 2) AS churn_rate_pct
FROM telco_churn
GROUP BY contract, payment_method
HAVING COUNT(*) >= 100
   AND AVG(CASE WHEN churn = 'Yes' THEN 1 ELSE 0 END) > 0.30
ORDER BY churn_rate_pct DESC;

-- 10. Ежемесячные платежи под риском по типам договора
WITH contract_stats AS (
    SELECT
        contract,
        COUNT(*) AS customers,
        COUNT(*) FILTER (WHERE churn = 'Yes') AS churned_customers,
        SUM(monthly_charges) FILTER (WHERE churn = 'Yes') AS monthly_revenue_lost
    FROM telco_churn
    GROUP BY contract
)
SELECT
    contract,
    customers,
    churned_customers,
    ROUND(monthly_revenue_lost, 2) AS monthly_revenue_lost,
    ROUND(100.0 * monthly_revenue_lost / SUM(monthly_revenue_lost) OVER (), 2) AS revenue_share_pct
FROM contract_stats
ORDER BY monthly_revenue_lost DESC;

-- 11. Клиенты с платежом выше среднего по своему типу договора (JOIN)
WITH contract_avg AS (
    SELECT
        contract,
        AVG(monthly_charges) AS avg_monthly_charges
    FROM telco_churn
    GROUP BY contract
)
SELECT
    c.contract,
    COUNT(*) AS customers_above_contract_average,
    ROUND(AVG(c.monthly_charges), 2) AS avg_monthly_charges
FROM telco_churn c
JOIN contract_avg a ON c.contract = a.contract
WHERE c.monthly_charges > a.avg_monthly_charges
GROUP BY c.contract
ORDER BY customers_above_contract_average DESC;
