-- Схема таблицы для демонстрационного датасета Telco Customer Churn.
-- Запуск: psql -U churn_user -d churn_db -f sql/01_create_tables.sql

DROP TABLE IF EXISTS telco_churn;

CREATE TABLE telco_churn (
    customer_id       VARCHAR(20) PRIMARY KEY,
    gender            VARCHAR(10) NOT NULL,
    senior_citizen    SMALLINT NOT NULL CHECK (senior_citizen IN (0, 1)),
    partner           VARCHAR(3) NOT NULL,
    dependents        VARCHAR(3) NOT NULL,
    tenure            SMALLINT NOT NULL CHECK (tenure >= 0),
    phone_service     VARCHAR(3) NOT NULL,
    multiple_lines    VARCHAR(20) NOT NULL,
    internet_service  VARCHAR(20) NOT NULL,
    online_security   VARCHAR(20) NOT NULL,
    online_backup     VARCHAR(20) NOT NULL,
    device_protection VARCHAR(20) NOT NULL,
    tech_support      VARCHAR(20) NOT NULL,
    streaming_tv      VARCHAR(20) NOT NULL,
    streaming_movies  VARCHAR(20) NOT NULL,
    contract          VARCHAR(20) NOT NULL,
    paperless_billing VARCHAR(3) NOT NULL,
    payment_method    VARCHAR(30) NOT NULL,
    monthly_charges   NUMERIC(10, 2) NOT NULL CHECK (monthly_charges >= 0),
    total_charges     NUMERIC(12, 2) CHECK (total_charges >= 0),
    churn             VARCHAR(3) NOT NULL CHECK (churn IN ('Yes', 'No'))
);

COMMENT ON TABLE telco_churn IS 'Демонстрационный датасет IBM Telco Customer Churn';
COMMENT ON COLUMN telco_churn.total_charges IS 'Пустое значение у клиентов с tenure = 0';
