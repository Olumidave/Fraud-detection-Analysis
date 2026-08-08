Bank Fraud Detection System — SQL Analytics Project
![SQL Server](https://img.shields.io/badge/Microsoft_SQL_Server-CC2927?style=for-the-badge&logo=microsoft-sql-server&logoColor=white)
![Power BI](https://img.shields.io/badge/Power_BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen?style=for-the-badge)
![Queries](https://img.shields.io/badge/Queries-35-blue?style=for-the-badge)
![Phases](https://img.shields.io/badge/Phases-6-orange?style=for-the-badge)
An end-to-end fraud detection system built entirely in Microsoft SQL Server.
From raw transaction data to executive-ready fraud intelligence — no machine learning required.
---
Table of Contents
Project Background
Executive Summary
Database Schema
Fraud Patterns
Methodology
Key Findings
Recommendations
Power BI Integration
How to Run
Files in This Repository
Technical Skills
About the Author
---
1. Project Background
Nigerian commercial banks process millions of transactions daily.
A significant percentage of those transactions are fraudulent — and most banks
lack the real-time analytical infrastructure to catch them before money leaves.
This project simulates the full fraud detection pipeline for a Nigerian bank,
covering one full calendar year of transaction data across 100 customers,
119 accounts, and 30 merchants.
The goal was to answer three questions every fraud team needs answered:
Where is the fraud hiding inside normal transaction behaviour?
What SQL rules can catch each fraud pattern before money leaves the bank?
How do we communicate fraud risk clearly to non-technical leadership?
The project uses only Microsoft SQL Server. No machine learning.
No external tools. No Python. Pure SQL applied systematically across six phases.
---
2. Executive Summary
Metric	Value
Total Transactions Analysed	657
Confirmed Fraud Cases	167 (25.4%)
Total Fraud Exposure	₦18,340,200
Fraud Already Paid Out	₦14,120,800
Fraud Still Stoppable (Pending)	₦3,240,600
Average Fraud Transaction	₦109,822
Largest Single Fraud Amount	₦1,998,400
Distinct Fraud Schemes Detected	7
Accounts Flagged for Suspension	23
> **The most critical number:** ₦3,240,600 in fraud transactions are still in Pending status.
> These can be stopped today if the fraud team acts immediately.
---
3. Database Schema
The database follows a Star Schema with TRANSACTIONS as the central fact table.
```
CUSTOMERS (100 rows)
     |
     | customer_id
     |
ACCOUNTS (119 rows)
     |
     | account_id
     |
TRANSACTIONS (657 rows) ----------- MERCHANTS (30 rows)
                         merchant_id
```
CUSTOMERS
Stores personal and financial profile of every bank customer.
Column	Type	Description
customer_id	CHAR(9)	Primary Key — CUST-0001 format
full_name	VARCHAR(60)	Customer full name
email	VARCHAR(80)	Email address
phone	VARCHAR(15)	Phone number
date_of_birth	DATE	Date of birth
city	VARCHAR(30)	Customer home city
country	VARCHAR(20)	Customer country
account_open_date	DATE	Date joined the bank
credit_score	INT	Score between 300 and 850
annual_income	DECIMAL(12,2)	Annual income in naira
risk_level	VARCHAR(10)	LOW, MEDIUM, or HIGH
ACCOUNTS
One customer can hold multiple accounts of different types.
Column	Type	Description
account_id	CHAR(9)	Primary Key — ACCT-0001 format
customer_id	CHAR(9)	Foreign Key → CUSTOMERS
account_type	VARCHAR(15)	Savings, Current, or Domiciliary
account_number	VARCHAR(12)	10-digit NUBAN number
balance	DECIMAL(15,2)	Current balance in naira
account_status	VARCHAR(15)	Active, Dormant, or Suspended
open_date	DATE	Date account was opened
credit_limit	DECIMAL(12,2)	Maximum credit in naira
MERCHANTS
Reference data for every merchant linked to transactions.
Column	Type	Description
merchant_id	CHAR(8)	Primary Key — MERCH-01 format
merchant_name	VARCHAR(50)	Merchant or business name
category	VARCHAR(20)	Retail, Crypto, Gambling, ATM, etc
city	VARCHAR(30)	Merchant city
country	VARCHAR(20)	Merchant country
risk_level	VARCHAR(10)	LOW, MEDIUM, or HIGH
TRANSACTIONS — Central Fact Table
Every transaction across all accounts and merchants.
Column	Type	Description
transaction_id	CHAR(10)	Primary Key — TXN-000001 format
account_id	CHAR(9)	Foreign Key → ACCOUNTS
merchant_id	CHAR(8)	Foreign Key → MERCHANTS
transaction_date	DATETIME	Full date and time
amount	DECIMAL(15,2)	Amount in naira
transaction_type	VARCHAR(20)	Purchase, Transfer, ATM Withdrawal, etc
location_city	VARCHAR(30)	City where transaction occurred
location_country	VARCHAR(20)	Country where transaction occurred
device_type	VARCHAR(20)	Mobile App, Web Browser, ATM, POS, USSD
transaction_status	VARCHAR(10)	Completed, Failed, or Pending
is_fraud	BIT	0 = Legitimate, 1 = Fraud
fraud_type	VARCHAR(40)	Fraud scheme label — NULL if legitimate
location_flag	VARCHAR(15)	CLEAN or NEEDS REVIEW — added in Phase 2
---
4. Fraud Patterns
Seven real-world fraud schemes were embedded into the transaction dataset.
#	Scheme	What It Looks Like	Why It Works
1	Velocity Fraud	5 or more transactions in 60 minutes	Stolen card drained before owner notices
2	Off-Hours Transaction	Large transfers between 1AM and 5AM	Fraud teams work business hours
3	Geographic Anomaly	Same card in Lagos and London within 3 hours	Physically impossible travel
4	Threshold Manipulation	Amounts between ₦950,000 and ₦999,999	Deliberately below ₦1M verification trigger
5	New Account Large Transaction	₦500K+ within first 30 days of opening	Account created specifically for fraud
6	Round Number Transaction	Exactly ₦500K, ₦1M, ₦2M at odd hours	Unusual precision at suspicious times
7	Multiple Failed Attempts	3 or more failures then success	Trying stolen credentials until one works
---
5. Methodology
This project follows a structured six-phase pipeline.
Each phase builds directly on the previous one.
Phase 1 — Data Profiling (6 queries)
Understand the complete shape of the dataset before writing any analytical query.
Query	Purpose
1.1	Row count per table — confirms data loaded correctly
1.2	NULL values across all TRANSACTIONS columns
1.3	Amount statistics — min, max, average, standard deviation
1.4	Fraud vs legitimate split with count and average amount
1.5	Date range — earliest, latest, days covered, active days
1.6	Distinct values per categorical column
Phase 2 — Data Cleaning (6 queries)
Fix every data quality problem before analysis begins.
Query	Issue Fixed
2.1	Duplicate transaction IDs
2.2	Zero or negative amount transactions
2.3	Orphaned transactions with no matching account
2.4	Completed transactions on suspended accounts
2.5	Unknown location flagging — adds location_flag column
2.6	Credit scores outside the valid 300 to 850 range
Phase 3 — Exploratory Analysis (8 queries)
Find where fraud hides inside normal transaction behaviour.
Query	Insight
3.1	Transaction volume and revenue by month
3.2	Transaction volume and fraud count by hour of day
3.3	Top 10 merchants by volume with fraud count
3.4	Fraud rate by merchant category
3.5	Fraud rate by device type
3.6	Fraud rate by transaction type
3.7	Top 10 accounts ranked by fraud transaction count
3.8	Domestic vs international fraud rate comparison
Phase 4 — Fraud Detection Rules (8 queries)
One SQL rule targeting each fraud pattern.
Query	Rule	SQL Technique
4.1	Velocity Fraud	Self-join with DATEADD 60-minute window
4.2	Off-Hours Transactions	DATEPART(hour) between 1 and 5
4.3	Geographic Anomaly	Self-join with DATEDIFF impossible travel check
4.4	Threshold Manipulation	BETWEEN 950000 AND 999999
4.5	New Account Large Transaction	DATEDIFF on account open_date
4.6	Dormant Account Reactivation	CTE with 180-day inactivity check
4.7	Multiple Failed Attempts	Conditional aggregation grouped by day
4.8	Round Number Transactions	Modulo operator — amount % 100000 = 0
Phase 5 — Risk Scoring (4 queries)
Every transaction and every account receives a numeric risk score from 0 to 100.
Transaction Scoring Model:
Signal	Points
Off-hours transaction between 1AM and 5AM	+25
Amount above ₦500,000	+20
International location	+20
High-risk merchant	+20
Round number amount	+10
Unknown location	+5
Risk Labels and Actions:
Score	Label	Action
60 and above	CRITICAL RISK	SUSPEND
40 to 59	HIGH RISK	REVIEW
20 to 39	MEDIUM RISK	MONITOR
Below 20	LOW RISK	CLEAR
Phase 6 — Business Recommendations (5 queries)
Translate findings into decisions leadership can act on today.
Query	Output
6.1	Executive dashboard — one row, eight KPIs
6.2	Monthly fraud trend with month-over-month change using LAG()
6.3	Suspension list with account ID, name, phone, and email
6.4	Fraud losses broken down by scheme with percentage of total
6.5	Prevention impact calculator — savings per detection rule
---
6. Key Findings
Fraud is concentrated in specific hours
Transactions between 1AM and 5AM carry a fraud rate more than three times higher
than business-hours transactions. High-value transfers while customers sleep
is the strongest single fraud signal in this dataset.
Geographic Anomaly causes the most financial damage
Fraud Scheme	Cases	Total Loss	Avg Per Case	% of Total
Geographic Anomaly	10	₦6,800,000	₦680,000	37.07%
Off-Hours Transaction	20	₦4,800,000	₦240,000	26.17%
Velocity Fraud	56	₦4,200,000	₦75,000	22.90%
Threshold Manipulation	15	₦1,480,000	₦98,667	8.07%
Multiple Failed Attempts	40	₦680,000	₦17,000	3.71%
Geographic Anomaly has the fewest cases but causes 37% of all fraud losses.
Web browser is the highest-risk device
Device	Fraud Rate
Web Browser	Highest
Mobile App	High
ATM	Medium
POS Terminal	Low
USSD	Lowest
International transactions are 6x riskier than domestic
Transactions processed outside Nigeria carry a fraud rate six times higher
than domestic transactions. Unknown location transactions have the highest
fraud rate of all — suggesting VPN or location-masking tools are being used.
Threshold manipulation is systematic
Multiple transactions clustering in the ₦950,000 to ₦999,999 range appear
across different accounts and different dates. This pattern does not exist
in legitimate customer behaviour.
---
7. Recommendations
Ordered by estimated annual financial impact:
Priority	Action	Fraud Scheme Targeted	Est. Annual Saving
1	Block card when same card appears in 2 countries within 3 hours	Geographic Anomaly	₦6,800,000
2	Require OTP for transactions above ₦50,000 between 1AM and 5AM	Off-Hours	₦4,800,000
3	Suspend account after 4th transaction in 60 minutes	Velocity Fraud	₦4,200,000
4	Flag all transactions between ₦950,000 and ₦999,999 for manual review	Threshold Manipulation	₦1,480,000
5	Limit transactions above ₦200,000 on accounts less than 30 days old	New Account	₦960,000
6	Lock account after 3 consecutive failed transactions	Multiple Failed Attempts	₦680,000
Combined estimated saving if all 6 rules are implemented: ₦18,920,000 annually
---
8. Power BI Integration
Six SQL views were created to connect this project directly to Power BI.
Each view is pre-aggregated so Power BI loads clean, structured data
without any additional transformation.
What is a View?
A view is a saved SQL query stored inside the database.
When Power BI connects to a view it sees a clean table — no raw joins,
no complex logic. The database does the heavy lifting.
Power BI gets the final result ready for visualisation.
Views Created
View Name	Powers in Power BI
vw_fraud_summary	KPI cards on the executive summary page
vw_fraud_by_month	Monthly trend line chart with MoM change
vw_fraud_by_type	Fraud scheme bar chart and pie chart
vw_fraud_by_device_and_type	Device and transaction type comparison charts
vw_account_risk_scores	Account risk table with score and recommended action
vw_suspension_list	Urgent action list with full contact details
How to Connect Power BI to SQL Server
Open Power BI Desktop
Click Home → Get Data → SQL Server
Enter your server name (visible in SSMS Object Explorer at the top)
Enter database name: `FraudDetectionDB`
Select Import as the data connectivity mode
In the Navigator panel, select all views starting with `vw_`
Click Load
> The complete views script is in `FRAUD_DETECTION_VIEWS.sql`
---
9. How to Run
Requirements
Microsoft SQL Server 2017 or later
SQL Server Management Studio (SSMS)
Power BI Desktop (optional — only needed for the dashboard)
Step 1 — Create the Database
```sql
CREATE DATABASE FraudDetectionDB;
GO
USE FraudDetectionDB;
GO
```
Step 2 — Load the Data
Open `FRAUD_DETECTION_DATA.sql` in SSMS and run the full script.
Verify data loaded correctly — expected output at end of script:
```
TableName        RowCount
-----------      --------
CUSTOMERS             100
ACCOUNTS              119
MERCHANTS              30
TRANSACTIONS          657
```
Fraud baseline verification:
```
is_fraud    count    percentage
--------    -----    ----------
0             490         74.6%
1             167         25.4%
```
If both outputs match — proceed to Step 3.
Step 3 — Run the Analysis
Open `FRAUD_DETECTION_ANALYSIS.sql` in SSMS.
Highlight each phase section individually and press F5 to run.
Read the output of each phase before moving to the next.
Step 4 — Create the Views
Open `FRAUD_DETECTION_VIEWS.sql` and run the full script.
This creates 6 views in FraudDetectionDB that Power BI can connect to.
Step 5 — Connect Power BI
Follow the steps in the Power BI Integration section above.
---
10. Files in This Repository
```
fraud-detection-sql/
│
├── README.md
│
├── FRAUD_DETECTION_DATA.sql
│       Creates all 4 tables
│       Inserts 657 transactions with 7 embedded fraud patterns
│       Adds FK constraints after bulk insert to avoid errors
│       Ends with row count and fraud baseline verification
│
├── FRAUD_DETECTION_ANALYSIS.sql
│       35 queries across 6 phases
│       Every query has an inline comment explaining what and why
│       Phases build sequentially — run in order
│
└── FRAUD_DETECTION_VIEWS.sql
        6 SQL views for Power BI connection
        Pre-aggregated and optimised for direct import
        Includes connection instructions at the bottom
```
---
11. Technical Skills
SQL Server Features Used
Feature	Applied In
Common Table Expressions (CTEs)	Phases 4, 5, 6
Window Functions — LAG(), RANK(), SUM() OVER()	Phases 5, 6
Self Joins	Queries 4.1 and 4.3
Conditional Aggregation — SUM(CASE WHEN)	All phases
DATEPART, DATEDIFF, DATEADD	Phases 3 and 4
NULLIF for division safety	Phases 5 and 6
Modulo operator for round number detection	Query 4.8
ALTER TABLE and schema modification	Phase 2
CREATE VIEW for Power BI data layer	Views script
Foreign key constraint management	Data script
Analytical Skills
Data quality assessment and systematic remediation
Fraud pattern recognition across 7 real-world schemes
Rule-based detection system design using pure SQL
Numeric risk scoring model construction
Executive KPI dashboard design
Month-over-month trend analysis using LAG()
Geographic anomaly detection using self joins
Financial impact quantification per fraud scheme
Power BI data layer design using SQL views
---
12. About the Author
Olumide — Data Analyst and BI Engineer
Specialising in SQL Server, Power BI, DAX, and data modelling
for financial services and enterprise analytics.
Based in Aba, Abia State, Nigeria.
![LinkedIn](https://www.linkedin.com/in/olumide-david-79b17726a/)
![GitHub](https://github.com/Olumidave)
---
> If this project was useful to you, please give it a ⭐ — it helps others find it.
---
Built with Microsoft SQL Server and Power BI · Nigerian Banking Context · 2024
