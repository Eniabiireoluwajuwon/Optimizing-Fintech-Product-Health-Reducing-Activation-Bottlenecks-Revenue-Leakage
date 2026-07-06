# Optimizing-Fintech-Product-Health-Reducing-Activation-Bottlenecks-Revenue-Leakage

## 📑 Executive Summary
In the highly competitive African fintech space, payment gateways operate on razor-thin margins driven by transaction volume. For this project, I stepped into the role of a Product Analyst to audit the ecosystem health of a payment gateway. 

The objective was to identify where the platform was losing merchants during onboarding, quantify revenue leakage from failed payments, and pinpoint vulnerabilities in the acquisition strategy. The resulting **Product Health Command Centre** revealed a critical 35% drop-off in merchant activation, over ₦73M in revenue leakage, and highlighted systemic risks in specific acquisition channels.

## 🎯 The Business Problem
A payment gateway only generates revenue when its merchants successfully process transactions. Stakeholders noticed a discrepancy between the marketing budget spent on acquiring new merchants and the actual transaction volume hitting the database. The executive team needed spontaneous, data-backed answers to four critical questions:
1. **The Activation Bottleneck:** Where are we losing merchants in the onboarding pipeline?
2. **Gateway Reliability:** How much revenue is leaking, and why?
3. **Fraud Risk:** Which marketing channels are bringing in bad actors?
4. **Operational SLA:** Are we resolving merchant support tickets fast enough to prevent churn?

## 🛠️ Data Architecture & Tools Used
To simulate a real-world enterprise environment, I built a robust data pipeline rather than importing flat files directly into a visualization tool:
* **Data Source:** A highly realistic synthetic dataset containing three core tables: `Merchants` (demographics & onboarding), `Transactions` (payment logs), and `Support Tickets`. 
* **SQL (Data Cleaning & Modeling):** Engineered the raw data into a relational database structure. Used SQL to clean anomalies, handle missing values (particularly for non-transacting merchants), and define Primary/Foreign key relationships (`merchant_id`). 
* **ODBC Connection:** Connected the visualization layer directly to the SQL database using an ODBC (Open Database Connectivity) driver, ensuring the dashboard could scale with live data updates.
* **Power BI:** Utilized for DAX measure creation, data modeling (Star Schema), and designing the final interactive Command Centre.

## 🧠 My Approach: From Raw Data to Strategy
1. **ETL & Data Modeling:** After importing the data via ODBC, I structured a Star Schema in Power BI. I created a centralized `Calendar` table to enable Time Intelligence functions.
2. **DAX Engineering:** I wrote custom DAX measures to calculate dynamic KPIs, such as `Activation Rate`, `Revenue Leakage`, and `Avg Resolution Time`.
3. **Visual UI/UX Design:** I designed a single-page executive view prioritizing scannability. I split the dashboard into three logical pillars: *Onboarding*, *Payments*, and *Risk*.

## 🔍 Key Insights Discovered
The data revealed several critical bottlenecks and operational realities:

* **The "API Integration" Chasm (Activation Rate: 64.9%):** The Onboarding Funnel shows that 100% of the 2.70K signups successfully completed KYC. However, a massive drop-off occurs at the API Integration stage, plummeting to 1.75K. We are losing 35% of acquired users strictly due to technical friction.
* **Quantifying Revenue Leakage (₦73.6M Lost):** While the gateway maintains a healthy 94.0% success rate, the 6% failure rate translates to ₦73.6M in lost volume. Root causes are evenly distributed across *Card Declines*, *Fraud Flags*, and *Insufficient Funds* (each contributing ~₦13M in lost value).
* **High-Risk Acquisition Channels:** Channel analysis revealed that "Partnerships" and the direct "Sales Team" are driving the highest volume of fraudulent transactions, far outpacing Organic or Paid Ads. 
* **The Q2 Acquisition Slump:** The Monthly Acquisition Velocity chart uncovered a sharp drop in new merchant signups beginning in May, crashing from ~320 signups/month to a plateau of ~160 averagely in the last 3 years.

---

## 🚧 Technical Challenge & Resolution
**The Cartesian Product Bug via ODBC:** 
During the initial SQL-to-Power BI load, my `Total Revenue` KPI was artificially inflated by billions of Naira. By tracing the logic back to my SQL environment, I realized that joining the `Transactions` table directly to the `Support Tickets` table on `merchant_id` created a Many-to-Many Cartesian explosion (since one merchant can have multiple transactions *and* multiple tickets). 

* **The Fix:** I resolved this by isolating the tables into a strict Star Schema within Power BI. I used the `Merchants` table as my central Dimension table (the "One" side), linking it to both `Transactions` and `Tickets` (the "Many" sides) using single-direction cross-filtering. This immediately corrected the DAX aggregations and stabilized the data model.


## 💡 Strategic Recommendations
Based on the dashboard insights, I recommend the following actions to the Product and Business teams:
1. **Overhaul the Developer Experience (DevEx):** The 35% drop-off at API integration means technical documentation is likely too complex. We should introduce "No-Code" payment links or better developer sandbox environments to bridge this gap.
2. **Audit Partnership SLAs:** Immediately review the vetting process for the "Partnerships" acquisition channel. Bringing in high fraud volume puts the gateway at risk of being penalized by card networks.
3. **Investigate the May/June Acquisition Crash:** The marketing team must conduct a post-mortem on Q2 to understand why top-of-funnel velocity was cut in half (e.g., did a major ad campaign end or a competitor launch a better pricing tier?).



## 📈 Business Impact
By transitioning from isolated CSVs to a relational SQL database and finally to this Power BI Command Centre, the business now has an automated, single source of truth. Executives no longer have to guess where revenue is leaking; they can track the exact monetary value of API friction and fraud in real-time, allowing them to allocate engineering and marketing resources efficiently.
