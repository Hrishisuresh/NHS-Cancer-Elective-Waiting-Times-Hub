# NHS Cancer & Elective Waiting Times Hub (Power BI & SQL)

## 📌 Table of Contents
* [Project Overview](#-project-overview)
* [Business Problem Statement](#-clinical--business-problem-statement)
* [Data Architecture & Pipeline](#-data-architecture--pipeline)
* [Design Principles](#-professional-nhs-identity--design-principles)
* [Operational Insights](#-core-operational-insights)
* [Governance & Compliance](#-information-governance--gdpr-compliance)
* [Replication Guide](#-how-to-replicate-this-project)

---

## 📌 Project Overview
This repository contains an enterprise-grade NHS performance and operational dashboard built using **Power BI Desktop** and **Microsoft SQL Server (T-SQL)**. 

### 📊 Final Dashboard Preview
![Dashboard Preview](Images/dashboard_preview.png)

---

## 🎯 Clinical & Business Problem Statement
NHS acute trusts face immense pressure to meet constitutional waiting time standards. Managing complex cancer and elective pathways requires clear visibility over bottleneck specialties and individual waiting times. This project addresses the visibility gap across five core metrics:

* **62-Day Cancer Standard (Target: 85%)**
* **Faster Diagnosis Standard (FDS 28-Day, Target: 75%)**
* **31-Day Cancer Standard (Target: 96%)**
* **PTL Backlog**
* **RTT 18-Week Referral to Treatment (Target: 92%)**

---

## 🛠️ Data Architecture & Pipeline
### 1. Upstream Data Warehousing (SQL Server)
All complex path logic, data cleansing, and cohort calculations were handled upstream inside **Microsoft SQL Server using T-SQL** to keep the Power BI model lightweight.

### 2. Downstream Data Modeling (Power BI)
A centralized dimension table (`patients`) connects via a clean **1-to-Many relationship** to the transactional tables (`cancer_analysis` and `rtt_analysis`) using the unique `patient_id` key.

---

## 🎨 Professional NHS Identity & Design Principles
The dashboard was developed in strict compliance with **Official NHS Identity Guidelines**:
* **Color Palette**: Uses **NHS Blue** (`#005EB8`), **NHS Dark Blue** (`#003087`), **NHS Red** (`#DA291C`), and **NHS Amber** (`#FFB81C`).
* **Layout Design**: Web-application grid format with 10px rounded corners and drop shadows.
* **Typography**: Set in **Arial** with strict sizing hierarchies.

---

## ⚙️ Core Operational Insights
* **Retrospective Performance**: Analyzes completed pathways to identify systemic department bottlenecks.
* **Forward-Looking Operational Control**: The **Active PTL Table** tracks patients whose waiting clocks are still ticking, allowing staff to focus on "At Risk" cohorts before they become breaches.

---

## 🔒 Information Governance & GDPR Compliance
* This repository uses completely **pseudonymized, synthetic data**.
* In a production environment, this dashboard is protected via **Row-Level Security (RLS)**.

---

## 🚀 How to Replicate This Project
1. Clone this repository.
2. Execute the T-SQL scripts in `/2_SQL_Scripts` to configure the views.
3. Open the `.pbix` file in `/3_PowerBI_Dashboard`.
4. Update the data source settings to point to your SQL Server instance and click **Refresh**.
