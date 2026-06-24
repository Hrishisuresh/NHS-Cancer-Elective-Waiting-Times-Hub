/*
====================================================================
Project: NHS Cancer & Elective Waiting Times Hub
Script Purpose: Database Schema Definition, Mock Data Injection, 
                and Operational Analytics Logic.
Author: Hrishi Suresh
Version: 1.0
Target Environment: Microsoft SQL Server (T-SQL)
Description: This script establishes the relational schema for 
             patient pathways, populates synthetic clinical data, 
             and calculates breach risk status (RAG ratings) and 
             performance trends for downstream Power BI reporting.
====================================================================
*/

-- ==========================================
-- 1. BUILD TABLES & SCHEMA
-- ==========================================
CREATE TABLE patients (
    patient_id VARCHAR(10) PRIMARY KEY,
    sex VARCHAR(1),
    age_band VARCHAR(10),
    gp_practice VARCHAR(50)
);

CREATE TABLE cancer_pathways (
    pathway_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10) FOREIGN KEY REFERENCES patients(patient_id),
    tumour_site VARCHAR(50),
    referral_date DATE,
    diagnosis_date DATE,
    decision_to_treat_date DATE,
    treatment_start_date DATE
);

CREATE TABLE rtt_pathways (
    pathway_id VARCHAR(10) PRIMARY KEY,
    patient_id VARCHAR(10) FOREIGN KEY REFERENCES patients(patient_id),
    specialty VARCHAR(50),
    referral_date DATE,
    active_monitoring_start_date DATE,
    treatment_start_date DATE,
    status VARCHAR(20)
);
GO

-- ==========================================
-- 2. INSERT SAMPLE TEST DATA
-- ==========================================
INSERT INTO patients VALUES 
('P0001', 'F', '50-64', 'Practice A'), ('P0002', 'M', '65-74', 'Practice B'), 
('P0003', 'F', '18-49', 'Practice C'), ('P0004', 'M', '75+', 'Practice A');

INSERT INTO cancer_pathways VALUES 
('CP01', 'P0001', 'Breast', '2026-04-01', '2026-04-15', '2026-04-20', '2026-05-10'), 
('CP02', 'P0002', 'Prostate', '2026-01-10', '2026-02-15', '2026-02-20', '2026-03-20'), 
('CP03', 'P0003', 'Skin', '2026-05-01', NULL, NULL, NULL), 
('CP04', 'P0004', 'Lung', '2026-02-01', '2026-02-20', '2026-02-25', NULL); 

INSERT INTO rtt_pathways VALUES 
('RP01', 'P0001', 'ENT', '2026-02-01', NULL, '2026-04-01', 'Completed'), 
('RP02', 'P0002', 'Urology', '2025-10-01', NULL, '2026-03-01', 'Completed'), 
('RP03', 'P0003', 'Gynaecology', '2026-05-01', NULL, NULL, 'Incomplete'), 
('RP04', 'P0004', 'Cardiology', '2026-01-01', '2026-02-01', NULL, 'Active Monitoring'); 
GO

-- ==========================================
-- 3. ANALYTICS QUERIES
-- ==========================================

-- Query A: Cancer Breaches (Completed Pathways)
SELECT 
    c.pathway_id, p.patient_id, c.tumour_site,
    DATEDIFF(day, c.referral_date, c.diagnosis_date) AS days_to_diagnosis,
    CASE WHEN DATEDIFF(day, c.referral_date, c.diagnosis_date) > 28 THEN 'FDS Breach' ELSE 'Within 28 days' END AS fds_status,
    DATEDIFF(day, c.decision_to_treat_date, c.treatment_start_date) AS days_decision_to_treatment,
    CASE WHEN DATEDIFF(day, c.decision_to_treat_date, c.treatment_start_date) > 31 THEN '31-day Breach' ELSE 'Within 31 days' END AS thirty_one_status,
    DATEDIFF(day, c.referral_date, c.treatment_start_date) AS days_referral_to_treatment,
    CASE WHEN DATEDIFF(day, c.referral_date, c.treatment_start_date) > 62 THEN '62-day Breach' ELSE 'Within 62 days' END AS sixty_two_status
FROM cancer_pathways c 
JOIN patients p ON c.patient_id = p.patient_id 
WHERE c.treatment_start_date IS NOT NULL 
ORDER BY days_referral_to_treatment DESC;
GO

-- Query B: Cancer PTL (Incomplete Pathways)
WITH ActivePTL AS (
    SELECT 
        pathway_id, patient_id, tumour_site, referral_date, 
        DATEDIFF(day, referral_date, '2026-06-30') AS days_waiting
    FROM cancer_pathways 
    WHERE treatment_start_date IS NULL
)
SELECT 
    pathway_id, patient_id, tumour_site, days_waiting,
    CASE 
        WHEN days_waiting > 62 THEN 'Breached >62' 
        WHEN days_waiting >= 50 THEN 'At risk >=50' 
        ELSE 'On track' 
    END AS breach_risk,
    RANK() OVER (ORDER BY days_waiting DESC, pathway_id ASC) AS wait_rank
FROM ActivePTL 
ORDER BY wait_rank;
GO

-- Query C: Cancer 62-Day Monthly Trend
WITH MonthlyStats AS (
    SELECT 
        FORMAT(treatment_start_date, 'yyyy-MM') AS treatment_month, 
        COUNT(*) AS total_treated,
        SUM(CASE WHEN DATEDIFF(day, referral_date, treatment_start_date) <= 62 THEN 1 ELSE 0 END) AS treated_within_62
    FROM cancer_pathways 
    WHERE treatment_start_date IS NOT NULL 
    GROUP BY FORMAT(treatment_start_date, 'yyyy-MM')
)
SELECT 
    treatment_month, total_treated, treated_within_62,
    CAST(treated_within_62 AS FLOAT) / total_treated * 100 AS performance_percentage,
    LAG(CAST(treated_within_62 AS FLOAT) / total_treated * 100) OVER (ORDER BY treatment_month) AS prev_month_performance
FROM MonthlyStats 
ORDER BY treatment_month;
GO

-- Query D: RTT 18-Week Logic (Handling Clock Stops)
SELECT 
    pathway_id, patient_id, specialty, status,
    CASE 
        WHEN status = 'Completed' THEN DATEDIFF(day, referral_date, treatment_start_date) 
        WHEN status = 'Incomplete' THEN DATEDIFF(day, referral_date, '2026-06-30') 
        ELSE NULL 
    END AS days_waited,
    CASE 
        WHEN status = 'Active Monitoring' THEN 'Clock Stopped' 
        WHEN status = 'Completed' AND DATEDIFF(day, referral_date, treatment_start_date) <= 126 THEN 'Treated Within 18w' 
        WHEN status = 'Completed' AND DATEDIFF(day, referral_date, treatment_start_date) > 126 THEN '18w Breach (Treated Late)' 
        WHEN status = 'Incomplete' AND DATEDIFF(day, referral_date, '2026-06-30') <= 126 THEN 'Waiting Within 18w' 
        WHEN status = 'Incomplete' AND DATEDIFF(day, referral_date, '2026-06-30') > 126 THEN '18w Breach (Still Waiting)' 
    END AS rtt_outcome
FROM rtt_pathways;
GO