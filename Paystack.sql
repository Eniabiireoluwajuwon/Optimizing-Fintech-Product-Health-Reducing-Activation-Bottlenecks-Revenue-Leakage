DROP DATABASE IF EXISTS `PAYSTACK`;
CREATE DATABASE `PAYSTACK`;
USE `PAYSTACK`;

SELECT * FROM paystack.merchants;
SELECT * FROM paystack.transactions;
SELECT * FROM paystack.support_tickets;


-- MERCHANT TABLE

CREATE TABLE valid_merchants AS

WITH staging AS (
    -- BASIC CLEANING or STANDARDIZATION
    SELECT
        merchant_id,
        -- Convert signup date to proper DATE type
        CAST(signup_date AS DATE) AS signup_date,
        
        -- Remove extra spaces in industry field
        TRIM(industry) AS industry,
        
        -- Standardize business size formatting (e.g. "small", "Medium")
        CONCAT(
            UPPER(LEFT(TRIM(business_size),1)),
            LOWER(SUBSTRING(TRIM(business_size),2))
        ) AS business_size,

        -- Standardize acquisition channel
        CONCAT(
            UPPER(LEFT(TRIM(acquisition_channel),1)),
            LOWER(SUBSTRING(TRIM(acquisition_channel),2))
        ) AS acquisition_channel,

        -- Standardize country naming format
        CONCAT(
            UPPER(LEFT(TRIM(country),1)),
            LOWER(SUBSTRING(TRIM(country),2))
        ) AS country,

        -- Ensure CAC is numeric and clean
        CAST(customer_acquisition_cost AS DECIMAL(10,2)) AS customer_acquisition_cost,

        -- Convert boolean-like flags to numeric (0/1)
        CAST(kyc_completed AS UNSIGNED) AS kyc_completed,
        CAST(api_integrated AS UNSIGNED) AS api_integrated,

        CAST(time_to_first_transaction_days AS UNSIGNED) AS time_to_first_transaction_days

    FROM paystack.merchants
    
    -- 👇 THE FIX: Filter out NULLs and Empty Strings here! 👇
    WHERE merchant_id IS NOT NULL
      AND signup_date IS NOT NULL
      AND industry IS NOT NULL AND TRIM(industry) != ''
      AND country IS NOT NULL AND TRIM(country) != ''
      AND business_size IS NOT NULL AND TRIM(business_size) != ''
      -- Add any other critical columns to this list as needed
),

deduped AS (
    -- REMOVE DUPLICATES BASED ON merchant_id
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY merchant_id
               ORDER BY signup_date DESC
           ) AS rn
    FROM staging
),

validated AS (
    -- KEEP ONLY ONE RECORD PER MERCHANT
    SELECT *
    FROM deduped
    WHERE rn = 1
)

-- FINAL OUTPUT TABLE
SELECT *
FROM validated;



-- TRANSACTIONS TABLE

CREATE TABLE valid_transactions AS

WITH staging AS (
    -- TYPE CLEANING AND FORMATTING
    SELECT
        transaction_id,
        merchant_id,

        CAST(transaction_date AS DATE) AS transaction_date,

        TRIM(payment_method) AS payment_method,

        CAST(NULLIF(transaction_value_ngn, '') AS DECIMAL(10,2)) AS transaction_value,
        CAST(NULLIF(paystack_revenue_ngn, '') AS DECIMAL(10,2)) AS paystack_revenue,

        CAST(
            CASE 
                WHEN transaction_success REGEXP '^[0-9]+$'
                THEN CAST(transaction_success AS UNSIGNED)
                ELSE NULL
            END AS UNSIGNED
        ) AS transaction_success,

        TRIM(NULLIF(failure_reason, '')) AS failure_reason,

        refund_flag,
        fraud_flag

    FROM paystack.transactions
),

cleaned AS (
    -- REMOVE INVALID VALUES
    SELECT *
    FROM staging
    WHERE transaction_value IS NOT NULL
),

deduped AS (
    -- REMOVE DUPLICATES
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY transaction_id
               ORDER BY transaction_date DESC
           ) AS rn
    FROM cleaned
),

validated AS (
    -- KEEP ONLY LATEST RECORD PER TRANSACTION
    SELECT *
    FROM deduped
    WHERE rn = 1
),

business_rules AS (
    -- BUSINESS LOGIC FILTERS
    SELECT *
    FROM validated
    WHERE transaction_value > 0
)

-- FINAL FACT TABLE
SELECT *
FROM business_rules;



-- SUPPORT TABLE

CREATE TABLE valid_support_tickets AS

WITH staging AS (
    -- BASIC CLEANING
    SELECT
        ticket_id,
        merchant_id,

        CAST(ticket_created_date AS DATE) AS ticket_created_date,

        TRIM(ticket_category) AS ticket_category,
        TRIM(ticket_status) AS ticket_status,

        CAST(resolution_time_hours AS DECIMAL(10,2)) AS resolution_time_hours

    FROM paystack.support_tickets
),

validated AS (
    -- REMOVE INVALID OR NEGATIVE RESOLUTION TIMES
    SELECT *
    FROM staging
    WHERE resolution_time_hours >= 0
      OR resolution_time_hours IS NULL
),

deduped AS (
    -- REMOVE DUPLICATE TICKETS
    SELECT *,
           ROW_NUMBER() OVER (
               PARTITION BY ticket_id
               ORDER BY ticket_created_date DESC
           ) AS rn
    FROM validated
),

final_support AS (
    -- KEEP ONLY ONE VERSION OF EACH TICKET
    SELECT *
    FROM deduped
    WHERE rn = 1
)

-- FINAL OUTPUT TABLE
SELECT *
FROM final_support; 

# SHOW TOP ACTIVE MERCHANTS
SELECT 
    m.merchant_id,
    m.industry,
    m.business_size,
    m.signup_date,
    
    -- Finding the exact date they became "active"
    MIN(t.transaction_date) AS first_transaction_date,
    
    -- Quantifying their activity level
    COUNT(t.transaction_id) AS total_successful_transactions,
    SUM(t.transaction_value) AS total_volume_processed

FROM valid_merchants m

-- We use INNER JOIN here because we strictly want merchants who exist in BOTH conditions
INNER JOIN valid_transactions t 
    ON m.merchant_id = t.merchant_id

-- The Activation Logic Filters
WHERE m.api_integrated = 1 
  AND t.transaction_success = 1  -- Ensuring we only count successful transactions

GROUP BY 
    m.merchant_id,
    m.industry,
    m.business_size,
    m.signup_date
    
ORDER BY 
    total_volume_processed DESC;
    
    
# TOTAL ACTIVE MERCHANTS
SELECT 
    COUNT(DISTINCT m.merchant_id) AS total_active_merchants
FROM valid_merchants m
INNER JOIN valid_transactions t 
    ON m.merchant_id = t.merchant_id
WHERE m.api_integrated = 1 
  AND t.transaction_success = 1;