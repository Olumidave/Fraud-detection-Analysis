# Fraud-detection-Analysis
An end-to-end fraud detection system built entirely in Microsoft SQL Server.  From raw transaction data to executive-ready fraud intelligence - no machine learning required.


Bank Fraud Detection System — SQL Analytics Project
<div align="center">
![SQL Server](https://img.shields.io/badge/Microsoft%20SQL%20Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)
![Queries](https://img.shields.io/badge/35%20Queries-6%20Phases-blue?style=for-the-badge)
<br/>
> An end-to-end fraud detection system built entirely in Microsoft SQL Server.  
> From raw transaction data to executive-ready fraud intelligence — no machine learning required.
<br/>
View the Data Script  ·  View the Analysis Script  ·  Jump to Findings  ·  Power BI Views
</div>
---
Table of Contents
Project Background
Executive Summary
Data Structure
Fraud Patterns
Methodology
Key Findings
Recommendations
Power BI Integration
Files
How to Run
Technical Skills
About the Author
---
Project Background
Nigerian commercial banks process millions of transactions daily.
A significant percentage of those transactions are fraudulent —
and most banks lack the real-time analytical infrastructure to catch them.
This project simulates the full fraud detection pipeline for a Nigerian bank,
covering one full calendar year of transaction data across 100 customers,
119 accounts, and 30 merchants.
The goal was to answer three questions that every fraud team and every
CFO needs answered:
Where is the fraud hiding inside normal transaction behaviour?
What SQL rules can catch each fraud pattern before money leaves?
How do we communicate fraud risk clearly to non-technical leadership?
The project uses only Microsoft SQL Server — no machine learning,
no external tools, no Python. Pure SQL applied systematically across six phases.
---
Executive Summary
Metric	Value
Total Transactions Analysed	657
Confirmed Fraud Cases	167 (25.4%)
Total Fraud Exposure	₦18,340,200
Fraud Already Paid Out	₦14,120,800
Fraud Still Stoppable (Pending)	₦3,240,600
Average Fraud Transaction	₦109,822
Largest Single Fraud	₦1,998,400
Fraud Patterns Detected	7 distinct schemes
Accounts Flagged for Suspension	23
The most important number: ₦3,240,600 in fraud transactions are
still in Pending status at time of analysis. These can be stopped today
if the fraud team acts immediately.
---
Data Structure
The database is built on a Star Schema with `TRANSACTIONS`
as the central fact table connected to three dimension tables.
```
                      ┌─────────────┐
                      │  CUSTOMERS  │
                      │  (100 rows) │
                      └──────┬──────┘
                             │ customer_id
                      ┌──────▼──────┐
                      │   ACCOUNTS  │
                      │  (119 rows) │
                      └──────┬──────┘
                             │ account_id
┌─────────────┐      ┌───────▼──────┐
│  MERCHANTS  │      │ TRANSACTIONS │
│  (30 rows)  ├──────►  (657 rows)  │
└─────────────┘      └──────────────┘
  merchant_id
```
CUSTOMERS
Stores personal and financial profile of every bank customer.
Column	Data Type	Description
customer_id	CHAR(9)	Primary Key · CUST-0001 format
full_name	VARCHAR(60)	Customer full name
email	VARCHAR(80)	Email address
phone	VARCHAR(15)	Phone number
date_of_birth	DATE	Date of birth
city	VARCHAR(30)	Customer home city
country	VARCHAR(20)	Customer country
account_open_date	DATE	Date they joined the bank
credit_score	INT	Credit score 300–850
annual_income	DECIMAL(12,2)	Annual income in naira
risk_level	VARCHAR(10)	LOW · MEDIUM · HIGH
ACCOUNTS
One customer can hold multiple account types.
Column	Data Type	Description
account_id	CHAR(9)	Primary Key · ACCT-0001 format
customer_id	CHAR(9)	Foreign Key → CUSTOMERS
account_type	VARCHAR(15)	Savings · Current · Domiciliary
account_number	VARCHAR(12)	10-digit NUBAN number
balance	DECIMAL(15,2)	Current balance in naira
account_status	VARCHAR(15)	Active · Dormant · Suspended
open_date	DATE	Date account was opened
credit_limit	DECIMAL(12,2)	Maximum credit in naira
MERCHANTS
Reference data for all merchants linked to transactions.
Column	Data Type	Description
merchant_id	CHAR(8)	Primary Key · MERCH-01 format
merchant_name	VARCHAR(50)	Merchant or business name
category	VARCHAR(20)	Retail · Crypto · Gambling · ATM · etc
city	VARCHAR(30)	Merchant city
country	VARCHAR(20)	Merchant country
risk_level	VARCHAR(10)	LOW · MEDIUM · HIGH
TRANSACTIONS ⭐ Central Fact Table
Every transaction that occurred across all accounts and merchants.
Column	Data Type	Description
transaction_id	CHAR(10)	Primary Key · TXN-000001 format
account_id	CHAR(9)	Foreign Key → ACCOUNTS
merchant_id	CHAR(8)	Foreign Key → MERCHANTS
transaction_date	DATETIME	Full date and time of transaction
amount	DECIMAL(15,2)	Transaction amount in naira
transaction_type	VARCHAR(20)	Purchase · Transfer · ATM Withdrawal · etc
location_city	VARCHAR(30)	City where transaction occurred
location_country	VARCHAR(20)	Country where transaction occurred
device_type	VARCHAR(20)	Mobile App · Web Browser · ATM · POS · USSD
transaction_status	VARCHAR(10)	Completed · Failed · Pending
is_fraud	BIT	0 = Legitimate · 1 = Fraud
fraud_type	VARCHAR(40)	Fraud scheme label (NULL if legitimate)
location_flag	VARCHAR(15)	CLEAN · NEEDS REVIEW (added in Phase 2)
---
Fraud Patterns
Seven real-world fraud schemes were programmatically embedded
into the transaction dataset to simulate production banking data.
#	Scheme	What It Looks Like	Why It Works
1	Velocity Fraud	5+ transactions in 60 minutes	Stolen card drained before owner notices
2	Off-Hours Transaction	Large transfers between 1AM–5AM	Fraud teams work business hours
3	Geographic Anomaly	Same card in Lagos and London within 3 hours	Physically impossible travel
4	Threshold Manipulation	Amounts between ₦950,000–₦999,999	Deliberately below ₦1M verification trigger
5	New Account Large Transaction	₦500K+ within first 30 days	Account opened specifically for fraud
6	Round Number Transaction	Exactly ₦500K, ₦1M, ₦2M at odd hours	Unusual precision at suspicious times
7	Multiple Failed Attempts	3+ failed attempts then success	Trying stolen credentials until one works
---
Methodology
This project follows a structured six-phase analytical process.
Each phase builds directly on the previous one.
```
Phase 1          Phase 2          Phase 3
Profiling   →   Cleaning    →   Exploration
Understand       Fix data         Find where
the data         quality          fraud hides
before           issues           inside normal
touching it      first            behaviour

Phase 4          Phase 5          Phase 6
Detection   →   Scoring     →   Recommendations
Write SQL        Give every       Turn findings
rules that       transaction      into decisions
catch each       a risk score     for leadership
fraud pattern    0 to 100
```
Phase 1 — Data Profiling `6 queries`
Understand the complete shape of the dataset before writing
a single analytical query.
Query	What It Checks
1.1	Row count per table — confirms data loaded correctly
1.2	NULL values across all TRANSACTIONS columns
1.3	Amount statistics — min, max, avg, standard deviation
1.4	Fraud vs legitimate split with count and average amount
1.5	Date range — earliest, latest, days covered, active days
1.6	Distinct values per categorical column
---
Phase 2 — Data Cleaning `6 queries`
Identify and fix data quality problems that would corrupt analysis.
Query	Issue Fixed
2.1	Duplicate transaction IDs
2.2	Zero or negative amount transactions
2.3	Orphaned transactions with no matching account
2.4	Completed transactions on suspended accounts
2.5	Unknown location flagging → adds `location_flag` column
2.6	Credit scores outside valid 300–850 range
---
Phase 3 — Exploratory Analysis `8 queries`
Understand normal transaction behaviour so anomalies
are visible by comparison.
Query	Insight Generated
3.1	Transaction volume and revenue by month
3.2	Transaction volume and fraud count by hour of day
3.3	Top 10 merchants by volume with fraud count attached
3.4	Fraud rate by merchant category
3.5	Fraud rate by device type
3.6	Fraud rate by transaction type
3.7	Top 10 accounts ranked by fraud transaction count
3.8	Domestic vs international fraud rate comparison
---
Phase 4 — Fraud Detection Rules `8 queries`
One SQL rule for each fraud pattern.
Query	Rule	Technique
4.1	Velocity Fraud	Self-join + DATEADD 60-minute window
4.2	Off-Hours Transactions	DATEPART(hour) between 1 and 5
4.3	Geographic Anomaly	Self-join + DATEDIFF impossible travel
4.4	Threshold Manipulation	BETWEEN 950000 AND 999999
4.5	New Account Large Transaction	DATEDIFF on account open_date
4.6	Dormant Account Reactivation	CTE + 180-day inactivity
4.7	Multiple Failed Attempts	Conditional aggregation by day
4.8	Round Number Transactions	Modulo operator — amount % 100000 = 0
---
Phase 5 — Risk Scoring `4 queries`
Every transaction and every account receives a numeric risk score.
Transaction Scoring Model (0–100 points):
Signal Present	Points Added
Off-hours transaction (1AM–5AM)	+25
Amount above ₦500,000	+20
International location	+20
High-risk merchant	+20
Round number amount	+10
Unknown location	+5
Risk Labels and Account Actions:
Score Range	Risk Label	Account Action
60 and above	CRITICAL RISK	SUSPEND
40 to 59	HIGH RISK	REVIEW
20 to 39	MEDIUM RISK	MONITOR
Below 20	LOW RISK	CLEAR
---
Phase 6 — Business Recommendations `5 queries`
Translate the findings into decisions leadership can act on.
Query	Output
6.1	Executive dashboard — one row, eight KPIs including fraud still stoppable
6.2	Monthly fraud trend with LAG() month-over-month change percentage
6.3	Suspension list — account ID, name, phone, email, recommended action
6.4	Fraud losses broken down by fraud scheme with percentage of total
6.5	Prevention impact calculator — how much each detection rule saves
---
Key Findings
Fraud Overview
25.4% of all transactions are confirmed fraud
Fraud transactions average ₦109,822 — 2.1x higher than legitimate average of ₦52,340
₦3,240,600 in fraud is still in Pending status and can be stopped now
23 accounts meet the threshold for immediate suspension
Finding 1 — Fraud Peaks Between 1AM and 5AM
Transactions between 1AM and 5AM carry a fraud rate more than three times
higher than business-hours transactions.
High-value transfers happening while customers are asleep is the
single strongest off-the-shelf fraud signal in this dataset.
Recommendation: Require OTP verification for all transactions
above ₦50,000 between 1AM and 5AM.
---
Finding 2 — Geographic Anomaly is the Most Expensive Scheme
Fraud Scheme	Cases	Total Loss	Avg Per Case	% of Total Fraud
Geographic Anomaly	10	₦6,800,000	₦680,000	37.07%
Off-Hours Transaction	20	₦4,800,000	₦240,000	26.17%
Velocity Fraud	56	₦4,200,000	₦75,000	22.90%
Threshold Manipulation	15	₦1,480,000	₦98,667	8.07%
Multiple Failed Attempts	40	₦680,000	₦17,000	3.71%
Geographic Anomaly has the fewest cases but causes 37% of all fraud losses.
Stopping this one scheme saves more money per rule than any other.
---
Finding 3 — Web Browser is the Highest Risk Device
Device	Fraud Rate
Web Browser	Highest
Mobile App	High
ATM	Medium
POS Terminal	Low
USSD	Lowest
Physical card-present transactions (POS) carry the lowest fraud rate.
Online channels that require only credentials — not the physical card —
are the most exploited.
---
Finding 4 — International Transactions are 6x Riskier
Transactions processed outside Nigeria have a fraud rate six times
higher than domestic transactions.
Unknown location transactions have the highest fraud rate of all —
higher than any specific foreign country — suggesting VPN or
location-masking tools are being used deliberately.
---
Finding 5 — Threshold Manipulation is Systematic
Multiple transactions clustering in the ₦950,000–₦999,999 range
appear across different accounts and different time periods.
This is not coincidence. Fraudsters are aware of the ₦1,000,000
verification trigger and are deliberately structuring transactions
to stay below it.
This pattern does not appear in legitimate customer behaviour.
---
Recommendations
Based on the findings above, the following controls should be implemented
in order of financial impact:
Priority	Action	Fraud Scheme Targeted	Estimated Annual Saving
1	Block card when detected in 2 countries within 3 hours	Geographic Anomaly	₦6,800,000
2	Require OTP for transactions above ₦50,000 between 1AM–5AM	Off-Hours	₦4,800,000
3	Suspend account after 4th transaction in 60 minutes	Velocity Fraud	₦4,200,000
4	Flag all transactions between ₦950,000–₦999,999 for manual review	Threshold Manipulation	₦1,480,000
5	Limit transactions above ₦200,000 on accounts less than 30 days old	New Account	₦960,000
6	Lock account after 3 consecutive failed transactions	Multiple Failed	₦680,000
Combined estimated saving if all 6 rules are implemented: ₦18,920,000 annually
---
Power BI Integration
Six SQL views were created to connect this project to Power BI.
Each view is pre-aggregated and query-optimised so Power BI
loads clean, ready-to-visualise data without additional transformation.
Why Views for Power BI?
A view is a saved SQL query stored in the database.
When Power BI connects to a view it sees a clean table — no joins,
no complex logic, no raw transaction data. The database does the
heavy lifting and Power BI gets the final result.
Views Created
View Name	Powers
`vw_fraud_summary`	KPI cards — total fraud, exposure, stoppable amount
`vw_fraud_by_month`	Monthly trend line chart
`vw_fraud_by_type`	Fraud scheme breakdown bar chart
`vw_fraud_by_device`	Device type pie or bar chart
`vw_account_risk_scores`	Account risk table and heat map
`vw_suspension_list`	Accounts requiring immediate action
How to Connect Power BI to SQL Server
Open Power BI Desktop
Click Get Data → SQL Server
Enter your server name (shown in SSMS Object Explorer)
Enter your database name: `FraudDetectionDB`
Select Import mode
In the Navigator, select the views prefixed with `vw_`
Click Load
> The views script is included in `FRAUD_DETECTION_VIEWS.sql`
---
Files
```
fraud-detection-sql/
│
├── README.md
│
├── sql/
│   ├── FRAUD_DETECTION_DATA.sql
│   │     Creates all 4 tables
│   │     Inserts 657 transactions with 7 embedded fraud patterns
│   │     Adds FK constraints after bulk insert
│   │     Ends with row count and fraud baseline verification
│   │
│   ├── FRAUD_DETECTION_ANALYSIS.sql
│   │     35 queries across 6 phases
│   │     Inline comment on every query explaining what and why
│   │     Runs in sequence — each phase builds on the previous
│   │
│   └── FRAUD_DETECTION_VIEWS.sql
│         6 SQL views for Power BI connection
│         Pre-aggregated and optimised for direct import
│
└── powerbi/
      FRAUD_DETECTION_DASHBOARD.pbix
            Executive summary page
            Monthly trend page
            Fraud scheme breakdown page
            Account risk page
            Suspension list page
```
---
How to Run
Requirements
Microsoft SQL Server 2017 or later
SQL Server Management Studio (SSMS)
Power BI Desktop (optional — for dashboard)
Step 1 — Create the Database
```sql
CREATE DATABASE FraudDetectionDB;
GO
USE FraudDetectionDB;
GO
```
Step 2 — Load the Data
Open `FRAUD_DETECTION_DATA.sql` in SSMS and run the full script.
Verify with the output at the end of the script:
```
TableName        RowCount
-----------      --------
CUSTOMERS             100
ACCOUNTS              119
MERCHANTS              30
TRANSACTIONS          657
```
Fraud baseline:
```
is_fraud    count    percentage
--------    -----    ----------
0             490         74.6%
1             167         25.4%
```
If both outputs match — data loaded correctly. Proceed to Step 3.
Step 3 — Run the Analysis
Open `FRAUD_DETECTION_ANALYSIS.sql` in SSMS.
Run each phase section individually. Highlight a section and press `F5`.
Do not run all 35 queries at once on the first pass — read the output
of each phase before moving to the next.
Step 4 — Create the Views (Optional — for Power BI)
Open `FRAUD_DETECTION_VIEWS.sql` and run the full script.
This creates 6 views in your database that Power BI can connect to directly.
Step 5 — Connect Power BI (Optional)
Open Power BI Desktop → Get Data → SQL Server → enter server and
database name → select views starting with `vw_` → Load.
---
Technical Skills
SQL Server Features Used
Feature	Applied In
Common Table Expressions (CTEs)	Phases 4, 5, 6
Window Functions — LAG(), RANK(), SUM() OVER()	Phases 5, 6
Self Joins	Queries 4.1, 4.3 — velocity and geo-anomaly
Conditional Aggregation — SUM(CASE WHEN)	All phases
DATEPART, DATEDIFF, DATEADD	Phases 3, 4
NULLIF for division safety	Phases 5, 6
Modulo operator for round number detection	Query 4.8
ALTER TABLE and schema modification	Phase 2
CREATE VIEW for Power BI layer	Views script
Foreign key constraint management	Data script
Analytical Skills Demonstrated
Data quality assessment and systematic remediation
Fraud pattern recognition across 7 real-world schemes
Rule-based detection system design in SQL
Numeric risk scoring model construction
Executive KPI dashboard design
Month-over-month trend analysis with LAG()
Geographic anomaly detection using self joins
Financial impact quantification per fraud scheme
Power BI data layer design using SQL views
---
About the Author
Olumide — Data Analyst and BI Engineer
Specialising in SQL Server, Power BI, DAX, and data modelling
for financial services and enterprise analytics.

![LinkedIn](https://www.linkedin.com/in/olumide-david-79b17726)
![GitHub](https://github.com/Olumidave)
![Email](olumidedavid375@gmail.com)
---
If this project was useful, please give it a ⭐ — it helps others find it.
---
Built with Microsoft SQL Server and Power BI · Nigerian Banking Context · 2024
