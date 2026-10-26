USE telecom_churn;
GO

-- Q1: What is the overall churn count and churn rate?
-- Exp: 1 row | total_accounts | churned_accounts | churn_pct
select count(*) as total_accounts,
sum(case when CHURN = 'yes' then 1 else 0 end) as churned_accounts,
round(cast(sum(case when CHURN = 'yes' then 1 else 0 end) as float) / count(*) * 100, 2) as churn_pct
from telecom_customers;

-- Q2: What is the churn rate for each CRM segment?
-- Exp: 10 rows | total_accounts | churned_accounts | churn_pct
select CRM_PID_Value_Segment, total_accounts, churned_accounts,
round(cast(churned_accounts as float) / total_accounts * 100, 2) as churn_pct
from (select CRM_PID_Value_Segment,
count(*) as total_accounts,
sum(case when CHURN = 'yes' then 1 else 0 end) as churned_accounts
from telecom_customers
group by CRM_PID_Value_Segment) t;

-- Q3: How much TotalRevenue is lost to churn, and what share of total revenue does that represent?
-- Exp: 1 row | total_revenue | churned_revenue | churned_share_pct
select round(sum(cast(TotalRevenue as float)), 2) as total_revenue,
round(sum(case when CHURN = 'yes' then cast(TotalRevenue as float) else 0 end), 2) as churned_revenue,
round(sum(case when CHURN = 'yes' then cast(TotalRevenue as float) else 0 end) / sum(cast(TotalRevenue as float)) * 100, 2) as churned_share_pct
from telecom_customers;

-- Q4: How do churned and active accounts differ on average ARPU, subscribers and revenue?
-- Exp: 2 rows (Yes, No) | avg_arpu | avg_total_subs | avg_total_revenue
select churn, round(AVG(cast(ARPU as float)), 2) as avg_arpu,
round(AVG(cast(Total_SUBs as float)), 2) as avg_total_subs,
round(AVG(cast(TotalRevenue as float)), 2) as avg_total_revenue
from telecom_customers
where ARPU != ''
group by churn;

-- Q5: How often does each churn-like signal appear among churned vs active accounts?
-- Exp: 2 rows (Yes, No) | pct_not_active | pct_suspended | pct_low_arpu
with flags as (
select CHURN,
case when Not_Active_subscribers = '' then 0 when cast(Not_Active_subscribers as float) > 0 then 1 else 0 end as f_not_active,
case when Suspended_subscribers = '' then 0 when cast(Suspended_subscribers as float) > 0 then 1 else 0 end as f_suspended,
case when ARPU = '' then 0 when cast(ARPU as float) < (select avg(cast(ARPU as float)) from telecom_customers where ARPU != '')
then 1 else 0 end as f_low_arpu
from telecom_customers
)
select CHURN,
round(100 * avg(cast(f_not_active * 1.0 as float)), 2) as pct_not_active,
round(100 * avg(cast(f_suspended * 1.0 as float)), 2) as pct_suspended,
round(100 * avg(cast(f_low_arpu * 1.0 as float)), 2) as pct_low_arpu
from flags
group by CHURN;

-- Q6: How many active accounts show at least one churn-like signal, and how much revenue do they carry?
-- Exp: 1 row | flagged_accounts | flagged_revenue | flagged_pct_of_active
with flags as (
select CHURN, TotalRevenue,
case when Not_Active_subscribers = '' then 0 when cast(Not_Active_subscribers as float) > 0 then 1 else 0 end as f_not_active,
case when Suspended_subscribers = '' then 0 when cast(Suspended_subscribers as float) > 0 then 1 else 0 end as f_suspended,
case when ARPU = '' then 0 when cast(ARPU as float) < (select avg(cast(ARPU as float)) from telecom_customers where ARPU <> '') then 1 else 0 end as f_low_arpu
from telecom_customers
)
select count(*) as flagged_accounts,
round(sum(cast(TotalRevenue as decimal(10,2))), 2) as flagged_revenue,
round(cast(100.0 * count(*) / (select count(*) from flags where CHURN = 'No') as float), 2) as flagged_pct_of_active
from flags
where CHURN = 'No' and (f_not_active = 1 or f_suspended = 1 or f_low_arpu = 1);