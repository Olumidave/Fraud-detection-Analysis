# Bank Fraud Detection System

![SQL Server](https://img.shields.io/badge/Microsoft_SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)
![Queries](https://img.shields.io/badge/35_Queries-6_Phases-blue?style=for-the-badge)

An end-to-end fraud detection system built entirely in Microsoft SQL Server — from raw transaction data to executive-ready fraud intelligence. No machine learning. No external tools. Just SQL.

---

## Table of Contents

1. [Project Background](#project-background)
2. [Executive Summary](#executive-summary)
3. [Database Schema](#database-schema)
4. [Fraud Patterns Detected](#fraud-patterns-detected)
5. [Methodology](#methodology)
6. [Key Findings](#key-findings)
7. [Recommendations](#recommendations)
8. [Power BI Integration](#power-bi-integration)
9. [How to Run](#how-to-run)
10. [Repository Structure](#repository-structure)
11. [Skills Demonstrated](#skills-demonstrated)
12. [Author](#author)

---

## Project Background

Nigerian commercial banks process millions of transactions daily. A significant percentage are fraudulent — and most banks lack the real-time analytical infrastructure to catch them before money leaves.

This project simulates the complete fraud detection pipeline for a Nigerian bank, covering one full year of transaction data across 100 customers, 119 accounts, and 30 merchants.

**Three questions this project answers:**

- Where is fraud hiding inside normal transaction behaviour?
- What SQL rules can catch each fraud pattern before money leaves?
- How do we communicate fraud risk clearly to leadership?

---

## Executive Summary

| Metric | Value |
|---|---|
| Total Transactions | 657 |
| Confirmed Fraud Cases | 167 |
| Fraud Rate | 25.4% |
| Total Fraud Exposure | ₦18,340,200 |
| Already Paid Out | ₦14,120,800 |
| Still Stoppable Today | ₦3,240,600 |
| Average Fraud Amount | ₦109,822 |
| Largest Single Fraud | ₦1,998,400 |
| Fraud Schemes Found | 7 |
| Accounts to Suspend | 23 |

The most critical number is ₦3,240,600 — fraud still sitting in Pending status that the fraud team can stop today.

---

## Database Schema

Star Schema design with TRANSACTIONS as the central fact table.

```
CUSTOMERS (100 rows)
      |
      | customer_id
      |
ACCOUNTS (119 rows)
      |
      | account_id
      |
TRANSACTIONS (657 rows) ---merchant_id--- MERCHANTS (30 rows)
```

### CUSTOMERS Table

| Column | Type | Description |
|---|---|---|
| customer_id | CHAR(9) | Primary Key |
| full_name | VARCHAR(60) | Customer full name |
| email | VARCHAR(80) | Email address |
| phone | VARCHAR(15) | Phone number |
| date_of_birth | DATE | Date of birth |
| city | VARCHAR(30) | Home city |
| country | VARCHAR(20) | Country |
| account_open_date | DATE | Date joined the bank |
| credit_score | INT | Score between 300 and 850 |
| annual_income | DECIMAL(12,2) | Annual income in naira |
| risk_level | VARCHAR(10) | LOW, MEDIUM, or HIGH |

### ACCOUNTS Table

| Column | Type | Description |
|---|---|---|
| account_id | CHAR(9) | Primary Key |
| customer_id | CHAR(9) | Foreign Key to CUSTOMERS |
| account_type | VARCHAR(15) | Savings, Current, or Domiciliary |
| account_number | VARCHAR(12) | 10-digit NUBAN number |
| balance | DECIMAL(15,2) | Balance in naira |
| account_status | VARCHAR(15) | Active, Dormant, or Suspended |
| open_date | DATE | Date account opened |
| credit_limit | DECIMAL(12,2) | Maximum credit in naira |

### MERCHANTS Table

| Column | Type | Description |
|---|---|---|
| merchant_id | CHAR(8) | Primary Key |
| merchant_name | VARCHAR(50) | Business name |
| category | VARCHAR(20) | Retail, Crypto, Gambling, ATM, etc |
| city | VARCHAR(30) | Merchant city |
| country | VARCHAR(20) | Merchant country |
| risk_level | VARCHAR(10) | LOW, MEDIUM, or HIGH |

### TRANSACTIONS Table (Fact Table)

| Column | Type | Description |
|---|---|---|
| transaction_id | CHAR(10) | Primary Key |
| account_id | CHAR(9) | Foreign Key to ACCOUNTS |
| merchant_id | CHAR(8) | Foreign Key to MERCHANTS |
| transaction_date | DATETIME | Full date and time |
| amount | DECIMAL(15,2) | Amount in naira |
| transaction_type | VARCHAR(20) | Purchase, Transfer, ATM Withdrawal, etc |
| location_city | VARCHAR(30) | City of transaction |
| location_country | VARCHAR(20) | Country of transaction |
| device_type | VARCHAR(20) | Mobile App, Web Browser, ATM, POS, USSD |
| transaction_status | VARCHAR(10) | Completed, Failed, or Pending |
| is_fraud | BIT | 0 is Legitimate, 1 is Fraud |
| fraud_type | VARCHAR(40) | Fraud scheme name, NULL if legitimate |
| location_flag | VARCHAR(15) | CLEAN or NEEDS REVIEW, added in Phase 2 |

---

## Fraud Patterns Detected

| Scheme | Description | Signal |
|---|---|---|
| Velocity Fraud | 5 or more transactions in 60 minutes | Stolen card being drained fast |
| Off-Hours Transaction | Large transfers between 1AM and 5AM | Fraudster avoids detection at night |
| Geographic Anomaly | Same card in 2 countries within 3 hours | Physically impossible travel |
| Threshold Manipulation | Amounts between ₦950,000 and ₦999,999 | Deliberately below ₦1M trigger |
| New Account Large Transaction | Over ₦500K within first 30 days | Account created for one-time fraud |
| Round Number Transaction | Exactly ₦500K or ₦1M at odd hours | Unusual precision at suspicious times |
| Multiple Failed Attempts | 3 or more failures then a success | Trying stolen credentials until one works |

---

## Methodology

### Phase 1 — Data Profiling

Understand the dataset before touching it.

| Query | Purpose |
|---|---|
| 1.1 | Row count per table |
| 1.2 | NULL values across all columns |
| 1.3 | Amount statistics — min, max, average, standard deviation |
| 1.4 | Fraud vs legitimate split |
| 1.5 | Date range and active days |
| 1.6 | Distinct values per category column |

---

### Phase 2 — Data Cleaning

Fix every data quality issue before analysis begins.

| Query | Issue Fixed |
|---|---|
| 2.1 | Duplicate transaction IDs |
| 2.2 | Zero or negative amounts |
| 2.3 | Orphaned transactions with no matching account |
| 2.4 | Completed transactions on suspended accounts |
| 2.5 | Unknown location flagging — adds location_flag column |
| 2.6 | Credit scores outside 300 to 850 range |

---

### Phase 3 — Exploratory Analysis

Find where fraud hides inside normal behaviour.

| Query | Insight |
|---|---|
| 3.1 | Volume and revenue by month |
| 3.2 | Volume and fraud count by hour of day |
| 3.3 | Top 10 merchants by volume with fraud count |
| 3.4 | Fraud rate by merchant category |
| 3.5 | Fraud rate by device type |
| 3.6 | Fraud rate by transaction type |
| 3.7 | Top 10 accounts by fraud count |
| 3.8 | Domestic vs international fraud comparison |

---

### Phase 4 — Fraud Detection Rules

One SQL rule for each fraud pattern.

| Query | Rule | Technique |
|---|---|---|
| 4.1 | Velocity Fraud | Self-join with DATEADD 60-minute window |
| 4.2 | Off-Hours Transactions | DATEPART(hour) between 1 and 5 |
| 4.3 | Geographic Anomaly | Self-join with DATEDIFF impossible travel |
| 4.4 | Threshold Manipulation | BETWEEN 950000 AND 999999 |
| 4.5 | New Account Large Transaction | DATEDIFF on account open_date |
| 4.6 | Dormant Account Reactivation | CTE with 180-day inactivity check |
| 4.7 | Multiple Failed Attempts | Conditional aggregation by day |
| 4.8 | Round Number Transactions | Modulo operator amount % 100000 = 0 |

---

### Phase 5 — Risk Scoring

Every transaction and account receives a score from 0 to 100.

**How the score is built:**

| Signal | Points |
|---|---|
| Off-hours transaction between 1AM and 5AM | +25 |
| Amount above ₦500,000 | +20 |
| International location | +20 |
| High-risk merchant | +20 |
| Round number amount | +10 |
| Unknown location | +5 |

**What the score means:**

| Score | Label | Action |
|---|---|---|
| 60 and above | CRITICAL RISK | SUSPEND |
| 40 to 59 | HIGH RISK | REVIEW |
| 20 to 39 | MEDIUM RISK | MONITOR |
| Below 20 | LOW RISK | CLEAR |

---

### Phase 6 — Business Recommendations

Translate findings into actions leadership can take today.

| Query | Output |
|---|---|
| 6.1 | Executive dashboard — one row, eight KPIs |
| 6.2 | Monthly trend with month-over-month percentage change |
| 6.3 | Suspension list with name, phone, and email attached |
| 6.4 | Fraud losses by scheme with percentage of total |
| 6.5 | Prevention impact calculator — savings per rule |

---

## Key Findings

### Fraud peaks between 1AM and 5AM

Transactions in these hours carry a fraud rate three times higher than
business-hours transactions. High-value transfers while customers sleep
is the strongest fraud signal in this dataset.

### Geographic Anomaly causes the most financial damage

| Scheme | Cases | Total Loss | Avg Per Case | Share of Fraud |
|---|---|---|---|---|
| Geographic Anomaly | 10 | ₦6,800,000 | ₦680,000 | 37.07% |
| Off-Hours Transaction | 20 | ₦4,800,000 | ₦240,000 | 26.17% |
| Velocity Fraud | 56 | ₦4,200,000 | ₦75,000 | 22.90% |
| Threshold Manipulation | 15 | ₦1,480,000 | ₦98,667 | 8.07% |
| Multiple Failed Attempts | 40 | ₦680,000 | ₦17,000 | 3.71% |

### Web browser carries the highest fraud rate by device

| Device | Risk Level |
|---|---|
| Web Browser | Highest |
| Mobile App | High |
| ATM | Medium |
| POS Terminal | Low |
| USSD | Lowest |

### International transactions are 6x riskier than domestic

Transactions outside Nigeria carry a fraud rate six times higher than domestic ones.
Unknown location transactions have the highest fraud rate of all.

### Threshold manipulation is deliberate and systematic

Transactions clustering in the ₦950,000 to ₦999,999 range appear across
multiple accounts on different dates. This pattern does not exist in
legitimate customer behaviour.

---

## Recommendations

| Priority | Action | Fraud Scheme | Est. Annual Saving |
|---|---|---|---|
| 1 | Block card when same card appears in 2 countries within 3 hours | Geographic Anomaly | ₦6,800,000 |
| 2 | Require OTP for amounts above ₦50,000 between 1AM and 5AM | Off-Hours | ₦4,800,000 |
| 3 | Suspend account after 4th transaction in 60 minutes | Velocity Fraud | ₦4,200,000 |
| 4 | Flag all transactions between ₦950,000 and ₦999,999 | Threshold Manipulation | ₦1,480,000 |
| 5 | Limit transactions above ₦200,000 on accounts under 30 days old | New Account | ₦960,000 |
| 6 | Lock account after 3 consecutive failed transactions | Multiple Failed | ₦680,000 |

Combined saving if all 6 rules are implemented: ₦18,920,000 annually

---

## Power BI Integration

Six SQL views connect this project to Power BI. Each view is pre-aggregated
so Power BI loads clean data without additional transformation.

### Views Created

| View | Powers in Power BI |
|---|---|
| vw_fraud_summary | KPI cards on executive page |
| vw_fraud_by_month | Monthly trend line chart |
| vw_fraud_by_type | Fraud scheme bar and pie charts |
| vw_fraud_by_device_and_type | Device and transaction type charts |
| vw_account_risk_scores | Account risk table and heat map |
| vw_suspension_list | Urgent action list with contact details |

### How to Connect Power BI

1. Open Power BI Desktop
2. Click Home then Get Data then SQL Server
3. Enter your server name from SSMS Object Explorer
4. Enter database name: FraudDetectionDB
5. Select Import mode
6. In Navigator, tick all views starting with vw_
7. Click Load

---

## How to Run

### Requirements

- Microsoft SQL Server 2017 or later
- SQL Server Management Studio (SSMS)
- Power BI Desktop (optional)

### Step 1 — Create the database

```sql
CREATE DATABASE FraudDetectionDB;
GO
USE FraudDetectionDB;
GO
```

### Step 2 — Load the data

Run `FRAUD_DETECTION_DATA.sql` in SSMS.

Expected output when complete:

```
TableName        RowCount
CUSTOMERS             100
ACCOUNTS              119
MERCHANTS              30
TRANSACTIONS          657
```

Fraud baseline:

```
is_fraud    count    percentage
0             490         74.6%
1             167         25.4%
```

### Step 3 — Run the analysis

Run `FRAUD_DETECTION_ANALYSIS.sql` one phase at a time.
Highlight a section and press F5 to run it.

### Step 4 — Create the views

Run `FRAUD_DETECTION_VIEWS.sql` to create the six Power BI views.

---

## Repository Structure

```
fraud-detection-sql/
│
├── README.md
│
├── FRAUD_DETECTION_DATA.sql
│       Creates all 4 tables
│       Inserts data with 7 embedded fraud patterns
│       Adds FK constraints after bulk insert
│       Ends with verification queries
│
├── FRAUD_DETECTION_ANALYSIS.sql
│       35 queries across 6 phases
│       Every query has an explanation comment
│       Run phase by phase in sequence
│
└── FRAUD_DETECTION_VIEWS.sql
        6 SQL views for Power BI
        Pre-aggregated and optimised
        Includes Power BI connection instructions
```

---

## Skills Demonstrated

| SQL Feature | Used In |
|---|---|
| Common Table Expressions | Phases 4, 5, 6 |
| Window Functions — LAG, RANK, SUM OVER | Phases 5, 6 |
| Self Joins | Queries 4.1 and 4.3 |
| Conditional Aggregation | All phases |
| DATEPART, DATEDIFF, DATEADD | Phases 3 and 4 |
| NULLIF for division safety | Phases 5 and 6 |
| Modulo operator | Query 4.8 |
| ALTER TABLE | Phase 2 |
| CREATE VIEW | Views script |

---

## Author

**Olumide** — Data Analyst and BI Engineer

SQL Server · Power BI · DAX · Data Modelling · Financial Analytics

Based in Nigeria

[![LinkedIn](https://img.shields.io/badge/LinkedIn-Connect-0077B5?style=flat-square&logo=linkedin&logoColor=white)](https://linkedin.com/in/yourprofile)
[![GitHub](https://img.shields.io/badge/GitHub-Olumidave-181717?style=flat-square&logo=github&logoColor=white)](https://github.com/Olumidave)

---

If this project was useful, please give it a star — it helps others find it.

---

*Microsoft SQL Server · Power BI · Nigerian Banking Context · 2024*
