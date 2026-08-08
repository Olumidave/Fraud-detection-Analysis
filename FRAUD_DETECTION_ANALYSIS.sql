
-- FRAUD DETECTION PROJECT - COMPLETE ANALYSIS
-- Microsoft SQL Server
-- Author: Olumide
-- All 6 Phases: Profiling - Cleaning → Exploration →
--               Detection → Risk Scoring → Recommendations

-- HOW TO USE:
-- 1. Run FRAUD_DETECTION_DATA.sql FIRST to load all data
-- 2. Then run this file phase by phase



--  PHASE 1: DATA PROFILING
--  Goal: Understand what is in the dataset before touching it


-- QUERY 1.1 - ROW COUNT PER TABLE
-- Tells you how many records exist in each table so you know the
-- size of the dataset you are working with
SELECT 'CUSTOMERS'    AS table_name, COUNT(*) AS row_count FROM CUSTOMERS
UNION ALL
SELECT 'ACCOUNTS',     COUNT(*) FROM ACCOUNTS
UNION ALL
SELECT 'MERCHANTS',    COUNT(*) FROM MERCHANTS
UNION ALL
SELECT 'TRANSACTIONS', COUNT(*) FROM TRANSACTIONS;


-- QUERY 1.2 - NULL CHECK ACROSS TRANSACTIONS TABLE
-- Finds columns that have missing values so you know where
-- data quality problems exist before you start analysis
SELECT
    SUM(CASE WHEN transaction_id     IS NULL THEN 1 ELSE 0 END) AS null_transaction_id,
    SUM(CASE WHEN account_id         IS NULL THEN 1 ELSE 0 END) AS null_account_id,
    SUM(CASE WHEN merchant_id        IS NULL THEN 1 ELSE 0 END) AS null_merchant_id,
    SUM(CASE WHEN transaction_date   IS NULL THEN 1 ELSE 0 END) AS null_date,
    SUM(CASE WHEN amount             IS NULL THEN 1 ELSE 0 END) AS null_amount,
    SUM(CASE WHEN transaction_type   IS NULL THEN 1 ELSE 0 END) AS null_type,
    SUM(CASE WHEN location_city      IS NULL THEN 1 ELSE 0 END) AS null_city,
    SUM(CASE WHEN location_country   IS NULL THEN 1 ELSE 0 END) AS null_country,
    SUM(CASE WHEN device_type        IS NULL THEN 1 ELSE 0 END) AS null_device,
    SUM(CASE WHEN transaction_status IS NULL THEN 1 ELSE 0 END) AS null_status
FROM TRANSACTIONS;


-- QUERY 1.3 - TRANSACTION AMOUNT STATISTICS
-- Shows minimum, maximum, average and total transaction amounts
-- so you know the range of values and can spot anything extreme
SELECT
    COUNT(*)                        AS total_transactions,
    MIN(amount)                     AS min_amount,
    MAX(amount)                     AS max_amount,
    ROUND(AVG(amount), 2)           AS avg_amount,
    ROUND(STDEV(amount), 2)         AS std_deviation,
    SUM(amount)                     AS total_volume
FROM TRANSACTIONS
WHERE transaction_status = 'Completed';


-- QUERY 1.4 - FRAUD VS LEGITIMATE TRANSACTION SPLIT
-- Shows how many transactions are flagged as fraud vs legitimate
-- This is your baseline fraud rate for the entire dataset
SELECT
    CASE WHEN is_fraud = 1 THEN 'Fraud' ELSE 'Legitimate' END AS transaction_label,
    COUNT(*)                                                    AS transaction_count,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2)        AS percentage_,
    ROUND(AVG(amount), 2)                                      AS avg_amount,
    SUM(amount)                                                AS total_amount
FROM TRANSACTIONS
GROUP BY is_fraud;


-- QUERY 1.5 - DATE RANGE CHECK
-- Shows the earliest and latest transaction dates so you know
-- the time period your data covers
SELECT
    MIN(transaction_date)   AS earliest_transaction,
    MAX(transaction_date)   AS latest_transaction,
    DATEDIFF(day, MIN(transaction_date), MAX(transaction_date)) AS days_covered,
    COUNT(DISTINCT CAST(transaction_date AS DATE))              AS active_days
FROM TRANSACTIONS;


-- QUERY 1.6 - DISTINCT VALUES PER CATEGORY COLUMN
-- Shows all unique values for key category columns so you know
-- what options exist in the data
SELECT 'transaction_type'   AS column_name, transaction_type   AS value, COUNT(*) AS count FROM TRANSACTIONS GROUP BY transaction_type
UNION ALL
SELECT 'transaction_status', transaction_status, COUNT(*) FROM TRANSACTIONS GROUP BY transaction_status
UNION ALL
SELECT 'device_type',        device_type,        COUNT(*) FROM TRANSACTIONS GROUP BY device_type
UNION ALL
SELECT 'location_country',   location_country,   COUNT(*) FROM TRANSACTIONS GROUP BY location_country
ORDER BY column_name, count DESC;


-- ================================================================
--  PHASE 2: DATA CLEANING
--  Goal: Fix data quality issues before analysis
-- ================================================================


-- QUERY 2.1 - CHECK DUPLICATE TRANSACTION IDs
-- Finds any transaction IDs that appear more than once
-- which would mean duplicate records exist in the table
SELECT
    transaction_id,
    COUNT(*) AS occurrences
FROM TRANSACTIONS
GROUP BY transaction_id
HAVING COUNT(*) > 1;


-- QUERY 2.2 - FIND TRANSACTIONS WITH ZERO OR NEGATIVE AMOUNTS
-- A transaction should never be zero or negative
-- These are data entry errors that need to be removed
SELECT
    transaction_id,
    account_id,
    amount,
    transaction_date,
    transaction_type
FROM TRANSACTIONS
WHERE amount <= 0;


-- QUERY 2.3 - FIND ORPHANED TRANSACTIONS (no matching account)
-- Transactions that reference account IDs not in the ACCOUNTS table
-- These records are broken and cannot be analysed properly
SELECT
    t.transaction_id,
    t.account_id,
    t.amount,
    t.transaction_date
FROM TRANSACTIONS t
WHERE NOT EXISTS (
    SELECT 1 FROM ACCOUNTS a WHERE a.account_id = t.account_id
);


-- QUERY 2.4 - CHECK SUSPENDED ACCOUNTS STILL TRANSACTING
-- If an account is suspended it should have NO completed transactions
-- Completed transactions on suspended accounts are a data problem
SELECT
    a.account_id,
    a.account_status,
    COUNT(t.transaction_id)  AS transaction_count,
    SUM(t.amount)            AS total_amount
FROM ACCOUNTS a
JOIN TRANSACTIONS t ON a.account_id = t.account_id
WHERE a.account_status = 'Suspended'
  AND t.transaction_status = 'Completed'
GROUP BY a.account_id, a.account_status;


-- QUERY 2.5 - STANDARDISE UNKNOWN LOCATION VALUES
-- Transactions with "Unknown" city or country cannot be
-- geo-analysed so flag them for review
SELECT
    COUNT(*) AS unknown_location_count,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM TRANSACTIONS), 2) AS pct_of_total
FROM TRANSACTIONS
WHERE location_city = 'Unknown'
   OR location_country = 'Unknown';


   -- Step 1: Add the new column
ALTER TABLE TRANSACTIONS
ADD location_flag VARCHAR(15) DEFAULT 'CLEAN';
GO

-- Step 2: Update it based on the condition
UPDATE TRANSACTIONS
SET location_flag = 'NEEDS REVIEW'
WHERE location_city = 'Unknown'
   OR location_country = 'Unknown';
GO

-- Step 3: Set everything else to CLEAN
UPDATE TRANSACTIONS
SET location_flag = 'CLEAN'
WHERE location_city <> 'Unknown'
  AND location_country <> 'Unknown';
GO

-- Step 4: Verify
SELECT
    location_flag,
    COUNT(*) AS transaction_count
FROM TRANSACTIONS
GROUP BY location_flag;


-- QUERY 2.6 - CUSTOMER CREDIT SCORE RANGE CHECK
-- Credit scores below 300 or above 850 are outside valid range
-- Flag them so bad data does not affect risk scoring later
SELECT
    customer_id,
    full_name,
    credit_score
FROM CUSTOMERS
WHERE credit_score < 300
   OR credit_score > 850;


--  PHASE 3: EXPLORATORY ANALYSIS
--  Goal: Find patterns and understand normal transaction behaviour
-


-- QUERY 3.1 - TRANSACTION VOLUME BY MONTH
-- Shows how many transactions and how much revenue came through
-- each month so you can spot seasonal patterns
SELECT
    YEAR(transaction_date)  AS txn_year,
    MONTH(transaction_date) AS txn_month,
    COUNT(*)                AS total_transactions,
    SUM(amount)             AS total_amount,
    ROUND(AVG(amount), 2)   AS avg_amount
FROM TRANSACTIONS
WHERE transaction_status = 'Completed'
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY txn_year, txn_month;


-- QUERY 3.2 - TRANSACTION VOLUME BY HOUR OF DAY
-- Shows which hours have the most transactions
-- Normal hours are 7AM to 10PM  anything outside that is suspicious
SELECT
    DATEPART(hour, transaction_date) AS hour_of_day,
    COUNT(*)                         AS total_transactions,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_count,
    ROUND(AVG(amount), 2)            AS avg_amount
FROM TRANSACTIONS
GROUP BY DATEPART(hour, transaction_date)
ORDER BY hour_of_day;


-- QUERY 3.3 - TOP 10 MERCHANTS BY TRANSACTION VOLUME
-- Shows which merchants process the most transactions and value
-- Helps identify merchants linked to high fraud rates
SELECT TOP 10
    m.merchant_name,
    m.category,
    m.risk_level,
    COUNT(t.transaction_id)  AS total_transactions,
    SUM(t.amount)            AS total_amount,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) AS fraud_count
FROM MERCHANTS m
JOIN TRANSACTIONS t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_name, m.category, m.risk_level
ORDER BY total_transactions DESC;


-- QUERY 3.4 - FRAUD RATE BY MERCHANT CATEGORY
-- Shows which merchant categories have the highest fraud rate
-- High fraud categories need stricter transaction controls
SELECT
    m.category,
    COUNT(t.transaction_id)                                     AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END)            AS fraud_count,
    ROUND(SUM(CASE WHEN t.is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(t.transaction_id) * 100, 2)                   AS fraud_rate_pct,
    SUM(CASE WHEN t.is_fraud=1 THEN t.amount ELSE 0 END)        AS fraud_amount
FROM MERCHANTS m
JOIN TRANSACTIONS t ON m.merchant_id = t.merchant_id
GROUP BY m.category
ORDER BY fraud_rate_pct DESC;


-- QUERY 3.5 - FRAUD RATE BY DEVICE TYPE
-- Shows which device type is used most for fraud
-- If mobile app fraud is high you may need stronger mobile authentication
SELECT
    device_type,
    COUNT(*)                                                     AS total_transactions,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END)               AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(*) * 100, 2)                                   AS fraud_rate_pct,
    ROUND(AVG(CASE WHEN is_fraud=1 THEN amount END), 2)          AS avg_fraud_amount
FROM TRANSACTIONS
GROUP BY device_type
ORDER BY fraud_rate_pct DESC;


-- QUERY 3.6 - FRAUD RATE BY TRANSACTION TYPE
-- Shows which transaction types have the highest fraud
-- Transfers and Online Payments are historically the riskiest
SELECT
    transaction_type,
    COUNT(*)                                                     AS total_transactions,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END)               AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(*) * 100, 2)                                   AS fraud_rate_pct,
    SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END)             AS total_fraud_amount
FROM TRANSACTIONS
GROUP BY transaction_type
ORDER BY fraud_rate_pct DESC;


-- QUERY 3.7 - TOP 10 ACCOUNTS BY FRAUD TRANSACTIONS
-- Ranks accounts by how many fraud transactions they have
-- These accounts need to be reviewed and possibly suspended
SELECT TOP 10
    t.account_id,
    c.full_name,
    c.city,
    COUNT(t.transaction_id)                                      AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END)             AS fraud_count,
    SUM(CASE WHEN t.is_fraud = 1 THEN t.amount ELSE 0 END)       AS total_fraud_amount
FROM TRANSACTIONS t
JOIN ACCOUNTS a  ON t.account_id   = a.account_id
JOIN CUSTOMERS c ON a.customer_id  = c.customer_id
GROUP BY t.account_id, c.full_name, c.city
HAVING SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END) > 0
ORDER BY fraud_count DESC;


-- QUERY 3.8 - FRAUD BY COUNTRY (DOMESTIC vs INTERNATIONAL)
-- Shows how much fraud comes from Nigeria vs foreign countries
-- International transactions carry much higher fraud risk
SELECT
    location_country,
    COUNT(*)                                                     AS total_transactions,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END)               AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(*) * 100, 2)                                   AS fraud_rate_pct,
    SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END)             AS total_fraud_amount
FROM TRANSACTIONS
GROUP BY location_country
ORDER BY fraud_rate_pct DESC;


-- ================================================================
--  PHASE 4: FRAUD DETECTION RULES
--  Goal: Write SQL rules that catch each fraud pattern
-- ================================================================


-- QUERY 4.1 - VELOCITY FRAUD (5+ transactions in 1 hour)
-- If one account makes 5 or more transactions within 60 minutes
-- it is likely a bot or a stolen card being used rapidly
WITH Velocity_Check AS (
    SELECT
        t1.transaction_id,
        t1.account_id,
        t1.transaction_date,
        t1.amount,
        t1.location_country,
        COUNT(t2.transaction_id) AS txns_in_last_60_min
    FROM TRANSACTIONS t1
    JOIN TRANSACTIONS t2
        ON  t1.account_id = t2.account_id
        AND t2.transaction_date BETWEEN DATEADD(minute, -60, t1.transaction_date)
                                    AND t1.transaction_date
        AND t2.transaction_status = 'Completed'
    WHERE t1.transaction_status = 'Completed'
    GROUP BY t1.transaction_id, t1.account_id, t1.transaction_date, t1.amount, t1.location_country
)
SELECT
    transaction_id,
    account_id,
    transaction_date,
    amount,
    txns_in_last_60_min,
    location_country,
    'Velocity Fraud' AS detection_rule
FROM Velocity_Check
WHERE txns_in_last_60_min >= 5
ORDER BY txns_in_last_60_min DESC;


-- QUERY 4.2 - OFF-HOURS FRAUD (transactions between 1AM and 5AM)
-- Most legitimate customers sleep at night
-- High-value transactions happening at 1AM to 5AM are suspicious
SELECT
    t.transaction_id,
    t.account_id,
    c.full_name,
    t.transaction_date,
    DATEPART(hour, t.transaction_date) AS hour_of_day,
    t.amount,
    t.transaction_type,
    t.device_type,
    'Off-Hours Transaction' AS detection_rule
FROM TRANSACTIONS t
JOIN ACCOUNTS a  ON t.account_id  = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
WHERE DATEPART(hour, t.transaction_date) BETWEEN 1 AND 5
  AND t.transaction_status = 'Completed'
  AND t.amount > 50000
ORDER BY t.amount DESC;


-- QUERY 4.3 - GEOGRAPHIC ANOMALY (same account in 2 countries within 3 hours)
-- If your card was used in Lagos at 8AM and in London at 10AM
-- that is physically impossible and is almost certainly fraud
WITH Location_Pairs AS (
    SELECT
        t1.transaction_id       AS txn1_id,
        t1.account_id,
        t1.transaction_date     AS txn1_date,
        t1.location_country     AS country1,
        t1.amount               AS amount1,
        t2.transaction_id       AS txn2_id,
        t2.transaction_date     AS txn2_date,
        t2.location_country     AS country2,
        t2.amount               AS amount2,
        DATEDIFF(minute, t1.transaction_date, t2.transaction_date) AS minutes_apart
    FROM TRANSACTIONS t1
    JOIN TRANSACTIONS t2
        ON  t1.account_id = t2.account_id
        AND t1.transaction_id < t2.transaction_id
        AND t1.location_country <> t2.location_country
        AND t1.location_country <> 'Unknown'
        AND t2.location_country <> 'Unknown'
        AND DATEDIFF(minute, t1.transaction_date, t2.transaction_date)
            BETWEEN 1 AND 180
)
SELECT
    account_id,
    txn1_id,
    txn1_date,
    country1,
    amount1,
    txn2_id,
    txn2_date,
    country2,
    amount2,
    minutes_apart,
    'Geographic Anomaly - Impossible Travel' AS detection_rule
FROM Location_Pairs
ORDER BY minutes_apart;


-- QUERY 4.4 - THRESHOLD MANIPULATION (just below ₦1,000,000)
-- Fraudsters split transactions to stay below reporting limits
-- Amounts between ₦950,000 and ₦999,999 are deliberately structured
SELECT
    t.transaction_id,
    t.account_id,
    c.full_name,
    t.transaction_date,
    t.amount,
    t.merchant_id,
    m.merchant_name,
    m.category,
    'Threshold Manipulation' AS detection_rule
FROM TRANSACTIONS t
JOIN ACCOUNTS a  ON t.account_id  = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
JOIN MERCHANTS m ON t.merchant_id = m.merchant_id
WHERE t.amount BETWEEN 950000 AND 999999
  AND t.transaction_status = 'Completed'
ORDER BY t.amount DESC;


-- QUERY 4.5 - NEW ACCOUNT LARGE TRANSACTION (within first 30 days)
-- Fraud accounts are opened quickly and used immediately
-- A new account making a transaction over ₦500,000 in first 30 days is high risk
SELECT
    t.transaction_id,
    t.account_id,
    c.full_name,
    a.open_date                                         AS account_opened,
    t.transaction_date,
    DATEDIFF(day, a.open_date, t.transaction_date)      AS days_since_opening,
    t.amount,
    t.transaction_type,
    'New Account Large Transaction' AS detection_rule
FROM TRANSACTIONS t
JOIN ACCOUNTS a  ON t.account_id  = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
WHERE DATEDIFF(day, a.open_date, t.transaction_date) <= 30
  AND t.amount > 500000
  AND t.transaction_status = 'Completed'
ORDER BY t.amount DESC;


-- QUERY 4.6 - DORMANT ACCOUNT SUDDENLY ACTIVE
-- An account with no transactions for 180+ days that suddenly
-- makes a large transaction is either fraud or account takeover
WITH Last_Activity AS (
    SELECT
        account_id,
        MAX(transaction_date) AS last_transaction_date
    FROM TRANSACTIONS
    GROUP BY account_id
),
Dormant_Accounts AS (
    SELECT
        account_id,
        last_transaction_date,
        DATEDIFF(day, last_transaction_date, GETDATE()) AS days_dormant
    FROM Last_Activity
    WHERE DATEDIFF(day, last_transaction_date, GETDATE()) > 180
)
SELECT
    t.transaction_id,
    t.account_id,
    c.full_name,
    d.last_transaction_date     AS last_seen_before,
    d.days_dormant,
    t.transaction_date          AS sudden_activity_date,
    t.amount,
    'Dormant Account Reactivation' AS detection_rule
FROM Dormant_Accounts d
JOIN TRANSACTIONS t  ON d.account_id  = t.account_id
JOIN ACCOUNTS a      ON t.account_id  = a.account_id
JOIN CUSTOMERS c     ON a.customer_id = c.customer_id
WHERE t.transaction_date > d.last_transaction_date
  AND t.amount > 200000
ORDER BY t.amount DESC;


-- QUERY 4.7 - MULTIPLE FAILED ATTEMPTS BEFORE SUCCESS
-- Fraudsters often try different card details until one works
-- 3 or more failed attempts followed by a success is a red flag
WITH Attempt_Analysis AS (
    SELECT
        account_id,
        merchant_id,
        CAST(transaction_date AS DATE)          AS txn_day,
        COUNT(*)                                AS total_attempts,
        SUM(CASE WHEN transaction_status = 'Failed'    THEN 1 ELSE 0 END) AS failed_attempts,
        SUM(CASE WHEN transaction_status = 'Completed' THEN 1 ELSE 0 END) AS success_count,
        MAX(CASE WHEN transaction_status = 'Completed' THEN amount END)   AS successful_amount
    FROM TRANSACTIONS
    GROUP BY account_id, merchant_id, CAST(transaction_date AS DATE)
)
SELECT
    a.account_id,
    c.full_name,
    aa.merchant_id,
    m.merchant_name,
    aa.txn_day,
    aa.failed_attempts,
    aa.success_count,
    aa.successful_amount,
    'Multiple Failed Attempts' AS detection_rule
FROM Attempt_Analysis aa
JOIN ACCOUNTS a  ON aa.account_id  = a.account_id
JOIN CUSTOMERS c ON a.customer_id  = c.customer_id
JOIN MERCHANTS m ON aa.merchant_id = m.merchant_id
WHERE aa.failed_attempts >= 3
  AND aa.success_count >= 1
ORDER BY aa.failed_attempts DESC;


-- QUERY 4.8 - ROUND NUMBER TRANSACTIONS (exactly ₦500K, ₦1M, ₦2M etc)
-- Real purchases rarely end in exactly round numbers
-- Round amounts especially at odd hours are a fraud signal
SELECT
    t.transaction_id,
    t.account_id,
    c.full_name,
    t.transaction_date,
    DATEPART(hour, t.transaction_date) AS hour_of_day,
    t.amount,
    m.merchant_name,
    m.category,
    'Suspicious Round Amount' AS detection_rule
FROM TRANSACTIONS t
JOIN ACCOUNTS a  ON t.account_id  = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
JOIN MERCHANTS m ON t.merchant_id = m.merchant_id
WHERE t.amount % 100000 = 0
  AND t.amount >= 100000
  AND t.transaction_status = 'Completed'
ORDER BY t.amount DESC;


-- ================================================================
--  PHASE 5: RISK SCORING
--  Goal: Give every account and transaction a risk score
-- ================================================================

-- QUERY 5.1 - ACCOUNT-LEVEL RISK SCORE
-- Rolls up all transaction risk signals to score each account
-- Accounts with high scores should be flagged for review or suspension
WITH Account_Risk AS (
    SELECT
        t.account_id,
        COUNT(*)                                                AS total_txns,
        SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END)        AS fraud_txns,
        SUM(CASE WHEN DATEPART(hour, t.transaction_date)
                      BETWEEN 1 AND 5 THEN 1 ELSE 0 END)       AS off_hours_txns,
        SUM(CASE WHEN t.location_country <> 'Nigeria'
                      THEN 1 ELSE 0 END)                       AS foreign_txns,
        SUM(CASE WHEN t.amount > 500000 THEN 1 ELSE 0 END)     AS large_txns,
        MAX(t.amount)                                          AS max_txn_amount,
        ROUND(AVG(t.amount), 2)                                AS avg_txn_amount
    FROM TRANSACTIONS t
    WHERE t.transaction_status = 'Completed'
    GROUP BY t.account_id
)
SELECT
    ar.account_id,
    c.full_name,
    c.credit_score,
    c.risk_level                                               AS customer_risk_level,
    ar.total_txns,
    ar.fraud_txns,
    ar.off_hours_txns,
    ar.foreign_txns,
    ar.large_txns,
    ar.max_txn_amount,
    ar.avg_txn_amount,

    -- Account risk score
    (ar.fraud_txns * 30
     + ar.off_hours_txns * 10
     + ar.foreign_txns * 10
     + ar.large_txns * 5)                                      AS account_risk_score,

    CASE
        WHEN (ar.fraud_txns * 30 + ar.off_hours_txns * 10
              + ar.foreign_txns * 10 + ar.large_txns * 5) >= 80 THEN 'SUSPEND'
        WHEN (ar.fraud_txns * 30 + ar.off_hours_txns * 10
              + ar.foreign_txns * 10 + ar.large_txns * 5) >= 40 THEN 'REVIEW'
        WHEN (ar.fraud_txns * 30 + ar.off_hours_txns * 10
              + ar.foreign_txns * 10 + ar.large_txns * 5) >= 20 THEN 'MONITOR'
        ELSE 'CLEAR'
    END AS recommended_action

FROM Account_Risk ar
JOIN ACCOUNTS a  ON ar.account_id = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
ORDER BY account_risk_score DESC;


-- QUERY 5.2 - MERCHANT RISK SCORE
-- Scores each merchant based on how much fraud happens through them
-- High-score merchants should face stricter transaction controls
SELECT
    m.merchant_id,
    m.merchant_name,
    m.category,
    m.risk_level                                               AS base_risk_level,
    COUNT(t.transaction_id)                                    AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END)           AS fraud_count,
    ROUND(SUM(CASE WHEN t.is_fraud=1 THEN 1.0 ELSE 0 END)
          / NULLIF(COUNT(*), 0) * 100, 2)                     AS fraud_rate_pct,
    SUM(CASE WHEN t.is_fraud=1 THEN t.amount ELSE 0 END)      AS total_fraud_amount,
    RANK() OVER (ORDER BY
        SUM(CASE WHEN t.is_fraud=1 THEN 1.0 ELSE 0 END)
        / NULLIF(COUNT(*), 0) DESC)                           AS fraud_rate_rank

FROM MERCHANTS m
LEFT JOIN TRANSACTIONS t ON m.merchant_id = t.merchant_id
GROUP BY m.merchant_id, m.merchant_name, m.category, m.risk_level
ORDER BY fraud_rate_pct DESC;


-- QUERY 5.3 - CUSTOMER RISK PROFILE SUMMARY
-- Full picture of every customer combining their credit score,
-- account behaviour, and transaction risk signals
SELECT
    c.customer_id,
    c.full_name,
    c.city,
    c.credit_score,
    c.risk_level,
    c.annual_income,
    COUNT(DISTINCT a.account_id)                                AS total_accounts,
    COUNT(t.transaction_id)                                     AS total_transactions,
    SUM(CASE WHEN t.is_fraud = 1 THEN 1 ELSE 0 END)            AS fraud_count,
    SUM(t.amount)                                              AS total_transacted,
    ROUND(AVG(t.amount), 2)                                    AS avg_transaction,
    MAX(t.transaction_date)                                    AS last_activity,
    DATEDIFF(day, MAX(t.transaction_date), GETDATE())          AS days_since_last_txn,
    CASE
        WHEN SUM(CASE WHEN t.is_fraud=1 THEN 1 ELSE 0 END) >= 5  THEN 'CRITICAL'
        WHEN SUM(CASE WHEN t.is_fraud=1 THEN 1 ELSE 0 END) >= 3  THEN 'HIGH'
        WHEN SUM(CASE WHEN t.is_fraud=1 THEN 1 ELSE 0 END) >= 1  THEN 'MEDIUM'
        ELSE 'CLEAN'
    END AS fraud_profile

FROM CUSTOMERS c
JOIN ACCOUNTS a     ON c.customer_id = a.customer_id
LEFT JOIN TRANSACTIONS t ON a.account_id = t.account_id
GROUP BY c.customer_id, c.full_name, c.city, c.credit_score, c.risk_level, c.annual_income
ORDER BY fraud_count DESC;


-- ================================================================
--  PHASE 6: BUSINESS RECOMMENDATIONS
--  Goal: Turn findings into decisions that protect the bank
-- ================================================================


-- QUERY 6.1 - EXECUTIVE FRAUD SUMMARY DASHBOARD
-- Single query that gives leadership all the key fraud numbers
-- at a glance: total exposure, fraud rate, average fraud amount
SELECT
    COUNT(*)                                                    AS total_transactions,
    SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END)              AS total_fraud_cases,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(*) * 100, 2)                                 AS fraud_rate_pct,
    SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END)           AS total_fraud_exposure,
    ROUND(AVG(CASE WHEN is_fraud=1 THEN amount END), 2)        AS avg_fraud_amount,
    MAX(CASE WHEN is_fraud=1 THEN amount END)                  AS largest_fraud_amount,
    SUM(CASE WHEN is_fraud=1 AND transaction_status='Completed'
             THEN amount ELSE 0 END)                           AS fraud_already_paid_out,
    SUM(CASE WHEN is_fraud=1 AND transaction_status='Pending'
             THEN amount ELSE 0 END)                           AS fraud_still_stoppable
FROM TRANSACTIONS;


-- QUERY 6.2 - MONTHLY FRAUD TREND
-- Shows whether fraud is getting better or worse each month
-- If fraud is rising month over month action must be taken NOW
SELECT
    YEAR(transaction_date)   AS year_,
    MONTH(transaction_date)  AS month_,
    COUNT(*)                 AS total_transactions,
    SUM(CASE WHEN is_fraud=1 THEN 1 ELSE 0 END)     AS fraud_count,
    ROUND(SUM(CASE WHEN is_fraud=1 THEN 1.0 ELSE 0 END)
          / COUNT(*) * 100, 2)                       AS fraud_rate_pct,
    SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END) AS fraud_amount,
    LAG(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END))
        OVER (ORDER BY YEAR(transaction_date), MONTH(transaction_date))
                             AS prev_month_fraud_amount,
    ROUND(
        (SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END)
         - LAG(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END))
           OVER (ORDER BY YEAR(transaction_date), MONTH(transaction_date)))
        / NULLIF(LAG(SUM(CASE WHEN is_fraud=1 THEN amount ELSE 0 END))
           OVER (ORDER BY YEAR(transaction_date), MONTH(transaction_date)), 0)
        * 100, 2)            AS month_over_month_change_pct
FROM TRANSACTIONS
GROUP BY YEAR(transaction_date), MONTH(transaction_date)
ORDER BY year_, month_;


-- QUERY 6.3 - ACCOUNTS TO SUSPEND IMMEDIATELY
-- Lists accounts that have triggered multiple fraud patterns
-- These are the highest priority accounts needing immediate action
WITH Fraud_Signals AS (
    SELECT
        t.account_id,
        SUM(CASE WHEN is_fraud = 1 THEN 1 ELSE 0 END)            AS confirmed_fraud_count,
        SUM(CASE WHEN is_fraud = 1 THEN amount ELSE 0 END)        AS confirmed_fraud_amount,
        SUM(CASE WHEN DATEPART(hour, transaction_date) BETWEEN 1 AND 5
                      AND transaction_status='Completed'
                 THEN 1 ELSE 0 END)                              AS off_hours_count,
        SUM(CASE WHEN location_country <> 'Nigeria'
                      AND transaction_status='Completed'
                 THEN 1 ELSE 0 END)                              AS foreign_count,
        SUM(CASE WHEN amount > 500000 AND transaction_status='Completed'
                 THEN 1 ELSE 0 END)                              AS large_txn_count
    FROM TRANSACTIONS t
    GROUP BY t.account_id
)
SELECT
    fs.account_id,
    c.full_name,
    c.phone,
    c.email,
    a.account_status,
    fs.confirmed_fraud_count,
    fs.confirmed_fraud_amount,
    fs.off_hours_count,
    fs.foreign_count,
    fs.large_txn_count,
    'SUSPEND IMMEDIATELY'    AS recommended_action,
    'Call customer to verify identity and freeze account' AS next_step
FROM Fraud_Signals fs
JOIN ACCOUNTS a  ON fs.account_id = a.account_id
JOIN CUSTOMERS c ON a.customer_id = c.customer_id
WHERE fs.confirmed_fraud_count >= 3
   OR (fs.off_hours_count >= 5 AND fs.foreign_count >= 2)
ORDER BY fs.confirmed_fraud_amount DESC;


-- QUERY 6.4 - FRAUD LOSSES BY FRAUD TYPE
-- Breaks down total fraud exposure by the type of fraud
-- Helps the fraud team know which schemes to prioritise stopping
SELECT
    fraud_type,
    COUNT(*)                AS fraud_case_count,
    SUM(amount)             AS total_loss,
    ROUND(AVG(amount), 2)   AS avg_loss_per_case,
    MAX(amount)             AS largest_single_loss,
    ROUND(SUM(amount) * 100.0 / SUM(SUM(amount)) OVER (), 2) AS pct_of_total_fraud
FROM TRANSACTIONS
WHERE is_fraud = 1
  AND fraud_type IS NOT NULL
GROUP BY fraud_type
ORDER BY total_loss DESC;


-- QUERY 6.5 - FRAUD PREVENTION IMPACT CALCULATOR
-- Shows how much money the bank could save by blocking
-- each type of fraud before it completes
-- Use this to justify investment in fraud controls
SELECT
    fraud_type,
    COUNT(*)                                                        AS cases,
    SUM(CASE WHEN transaction_status='Completed' THEN amount ELSE 0 END) AS already_lost,
    SUM(CASE WHEN transaction_status='Pending'   THEN amount ELSE 0 END) AS still_stoppable,
    SUM(amount)                                                    AS total_exposure,

    CASE
        WHEN fraud_type = 'Velocity Fraud'
            THEN 'Block account after 4th transaction in 60 minutes'
        WHEN fraud_type = 'Off-Hours Transaction'
            THEN 'Require OTP confirmation for transactions between 1AM-5AM'
        WHEN fraud_type = 'Geographic Anomaly'
            THEN 'Alert customer and block if card used in 2 countries within 3 hours'
        WHEN fraud_type = 'Threshold Manipulation'
            THEN 'Flag all transactions between 950,000 and 999,999 for manual review'
        WHEN fraud_type = 'New Account Large Transaction'
            THEN 'Limit transactions above 200,000 for first 30 days on new accounts'
        WHEN fraud_type LIKE '%Round Number%'
            THEN 'Flag round-number transactions above 100,000 during off-hours'
        WHEN fraud_type = 'Multiple Failed Attempts'
            THEN 'Lock account after 3 consecutive failed transactions'
        ELSE 'Review and update fraud controls'
    END AS prevention_rule

FROM TRANSACTIONS
WHERE is_fraud = 1
  AND fraud_type IS NOT NULL
GROUP BY fraud_type
ORDER BY total_exposure DESC;


-- ================================================================
-- END OF FRAUD DETECTION ANALYSIS
-- ================================================================
-- Total Queries:  35
-- Phase 1 (Profiling):       6 queries
-- Phase 2 (Cleaning):        6 queries
-- Phase 3 (Exploration):     8 queries
-- Phase 4 (Detection):       8 queries
-- Phase 5 (Risk Scoring):    4 queries
-- Phase 6 (Recommendations): 5 queries
-- ================================================================
