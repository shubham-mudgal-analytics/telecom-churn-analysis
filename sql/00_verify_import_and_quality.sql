USE telecom_churn;
GO

-- Q1: How many rows are in the table?
-- Exp: 8453
select count(*) as total_cnt from telecom_customers;

-- Q2: How many blank values does each column have?
-- Exp: Segment 5 | ZIP 2 | ARPU 1 | Not_Active 4,149 | Suspended 8,101
SELECT
    SUM(CASE WHEN CRM_PID_Value_Segment IS NULL OR CRM_PID_Value_Segment = '' THEN 1 ELSE 0 END) AS Blank_Segment,
    SUM(CASE WHEN Billing_ZIP IS NULL OR Billing_ZIP = '' THEN 1 ELSE 0 END)                     AS Blank_ZIP,
    SUM(CASE WHEN ARPU IS NULL OR ARPU = '' THEN 1 ELSE 0 END)                                   AS Blank_ARPU,
    SUM(CASE WHEN Not_Active_subscribers IS NULL OR Not_Active_subscribers = '' THEN 1 ELSE 0 END) AS Blank_NotActive,
    SUM(CASE WHEN Suspended_subscribers IS NULL OR Suspended_subscribers = '' THEN 1 ELSE 0 END)   AS Blank_Suspended
FROM telecom_customers;

-- Q3: How many PIDs are duplicated, and how many rows do they occupy?
-- Exp: 6 PIDs | 23 rows
select count(*) as count_repeated_pid, sum(pid_repeated_cnt) as total_repeated_rows
from (select pid, count(*) as pid_repeated_cnt from telecom_customers
group by pid having count(*) > 1) t;

-- Q4: Which PIDs are duplicated?
-- Exp: 6 rows, one per duplicated PID
select pid, count(*) as pid_repeated_cnt from telecom_customers
group by pid having count(*) > 1;

-- Q5: How many PIDs are stored in scientific notation (contain 'E')?
-- Exp: 26
select count(*) as pid_count from telecom_customers
where pid like '%E%';

-- Q6: How many accounts are in each churn group?
-- Exp: Yes 549 | No 7,904
select churn, count(*) as churn_count from telecom_customers
group by churn;

-- Q7: Do the three subscriber counts add up to Total_SUBs?
-- Exp: 0 rows
select Active_subscribers, Not_Active_subscribers, Suspended_subscribers, Total_SUBs,
(coalesce(Active_subscribers,0) + coalesce(Not_Active_subscribers,0) + coalesce(Suspended_subscribers,0)) as Check_Total_Subscribers
from telecom_customers
where (coalesce(Active_subscribers,0) + coalesce(Not_Active_subscribers,0) + coalesce(Suspended_subscribers,0)) != Total_SUBs;

-- Q8: Does TotalRevenue equal the Mobile plus Fixed revenue?
-- Exp: 0 rows
select TotalRevenue,
(coalesce(cast(AvgMobileRevenue as decimal(10,2)),0) + coalesce(cast(AvgFIXRevenue as decimal(10,2)),0)) as Check_Total_Revenue
from telecom_customers
where (coalesce(cast(AvgMobileRevenue as decimal(10,2)),0) + coalesce(cast(AvgFIXRevenue as decimal(10,2)),0)) != TotalRevenue;

-- Q9: Which rows have a blank ARPU, and how many?
-- Exp: '' | 1
select ARPU, count(*) as blank_arpu_count from telecom_customers
where ARPU is null or ARPU = '' or ARPU = ' '
group by ARPU;

-- Q10: Which rows have an ARPU that differs from TotalRevenue ÷ Active_subscribers by more than 0.01?
-- Exp: 122 rows
select TotalRevenue, Active_subscribers, ARPU,
round(cast(TotalRevenue as float) / case when cast(Active_subscribers as float) = 0
then null else cast(Active_subscribers as float) end, 2) as Check_ARPU
from telecom_customers
where ARPU != ''
and abs(cast(TotalRevenue as float) / case when cast(Active_subscribers as float) = 0
then null else cast(Active_subscribers as float) end - cast(ARPU as float)) > 0.01;

-- Q11: How many rows are in each CRM segment? (Shows the blank and the typo 'Sliver')
-- Exp: Silver 2,039 | Sliver 1 | blank 5 | total 8,453
select CRM_PID_Value_Segment, count(*) as cnt from telecom_customers
group by CRM_PID_Value_Segment;

-- Q12: Which distinct KA_name values exist?
-- Exp: 12 values
select distinct KA_name from telecom_customers order by KA_name;

-- Q13: How many rows are in each CRM segment and EffectiveSegment combination?
-- Exp: 28 combinations | total 8,453
select CRM_PID_Value_Segment, EffectiveSegment, count(*) as cnt from telecom_customers
group by CRM_PID_Value_Segment, EffectiveSegment
order by count(*) desc;

-- Q14: Do all rows with a blank Not_Active reconcile (Active + Suspended = Total_SUBs)?
-- Exp: 4149 rows
select coalesce(Active_subscribers,0) as Active_subscribers, coalesce(Suspended_subscribers,0) as Suspended_subscribers,
Total_SUBs, count(*) over() as Total_Cnt from telecom_customers
where (Not_Active_subscribers is null or Not_Active_subscribers = '') and ((coalesce(Active_subscribers,0) + coalesce(Suspended_subscribers,0)) = Total_SUBs);
