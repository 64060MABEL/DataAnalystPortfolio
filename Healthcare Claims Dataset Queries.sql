/*
===============================================================================
Healthcare Claims & Revenue Leakage Analysis
===============================================================================
Description:
    This SQL script conducts an exploratory data analysis on healthcare claims 
    to evaluate claim disposition (Denied vs. Paid vs. Under Review), calculate 
    revenue leakage metrics (recoverable vs. written-off amounts), and categorize 
    denial reason codes into operational, patient-side, and payer coverage issues.

===============================================================================

*/Select * from dbo.Claims_data$;

-- 1. What % of claims are Denied Vs Paid Vs Under Review?
Select [Claim Status],
Count(*) as Claim_count,
Cast(Count(*) * 100/Sum(Count(*)) over () as decimal(5,2)) as percentage
From dbo.Claims_data$
Group by [Claim Status]
Order by Claim_count DESC;

-- 2. What is the Total Rev leakage and how much is recoverable Vs written off
Select
SUM(Leakage) as total_leakage,
SUM([Billed Amount] - [Allowed Amount]) as total_written_off,
SUM([Allowed Amount] - [Paid Amount]) as total_recoverable,
Cast(SUM([Billed Amount] - [Allowed Amount])*100.0/ SUM(Leakage) as decimal(5,2)) as written_off_pct,
Cast(SUM([Allowed Amount] - [Paid Amount])*100.0/SUM(Leakage) as decimal(5,2)) as recoverable_pct
From dbo.Claims_data$;

-- 3. Which reason codes cause the most denials is it operational or patient side?
Select  [Reason code] ,
Count(*) as denial_count,
Sum(leakage) as total_leakage,
CAST(Count(*)*100.0/sum(count(*)) over() as decimal(5,2)) as pct_of_denials,
CASE WHEN [Reason Code] In ('Incorrect billing information','Missing documentation','Duplicate claim','Authorization not obtained')
Then 'Operational'
When [Reason Code] In ('Patient eligibility issues','Pre-existing condition')
Then 'Patient-side'
When [Reason Code] In ('Lack of medical necessity','Service not covered')
Then 'Payer/Coverage'
Else 'Other'
End as category
From dbo.Claims_data$
Where [Claim Status] = 'Denied'
Group by [Reason Code]
Order by denial_count Desc;

-- Which Insurance type has the worst denial rates?

Select 
[Insurance Type],
COUNT(*) as total_claims,
SUM([Denial Flag]) as denial_count,
CAST(SUM([Denial Flag])*100.0/COUNT(*) AS Decimal(5,2)) as denial_rate_pct,
SUM(Leakage) As total_leakage
From dbo.Claims_data$
Group by [Insurance Type]
Order by denial_rate_pct DESC;

-- Which provider have denial rate way above average?
WITH provider_rates as 
(Select 
[Provider ID],
Count(*) as total_claims,
SUM([Denial Flag]) as denied_count,
Cast(SUM([Denial Flag])*100.0/count(*) as decimal(5,2)) as denial_rate_pct
From dbo.Claims_data$
Group by [Provider ID])
Select 
*,
(Select AVG(denial_rate_pct) from provider_rates) as overall_avg_denial_rate
From provider_rates
where denial_rate_pct > (Select AVG(denial_rate_pct) from provider_rates)
Order by denial_rate_pct desc;

-- Of claims needing Follow up how many are stuck in AR Limbo (Open/Pending/On hold) Vs closed
Select 
Case 
When [AR Status] = 'Closed' Then 'Closed'
Else 'Unresolved'
end as ar_bucket,
Count(*) as claim_count,
CAST(Count(*) * 100.0 / SUM(COUNT(*)) OVER() As decimal(5,2)) as pct_of_followups,
SUM(leakage) as total_leakage
From dbo.Claims_data$
Where [Follow-up Required]='Yes'
Group by 
Case when [AR Status] = 'Closed' Then 'Closed'
Else 'Unresolved'
End
order by claim_count desc;


