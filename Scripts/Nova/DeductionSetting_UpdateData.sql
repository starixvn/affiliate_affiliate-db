/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/

/*
	Created: 20210329@Percy
	DB: DBAFFN88-Affiliate_N88
*/

-- Affiliate_N8G
update Affiliate_N8G.dbo.DeductionSetting with (rowlock, updlock)
set DeductedPercentage = 0.1, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1
	and GroupId = 1

update Affiliate_N8G.dbo.DeductionSettingHistory with (rowlock, updlock)
set DeductedPercentage = 0.1, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1
	and MonthDate >= '2021-01-31'
	and GroupId = 1


-- Affiliate_N8B
update Affiliate_N8B.dbo.DeductionSetting with (rowlock, updlock)
set DeductedPercentage = 0.12, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1
	and GroupId = 1

update Affiliate_N8B.dbo.DeductionSettingHistory with (rowlock, updlock)
set DeductedPercentage = 0.12, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1
	and MonthDate >= '2021-01-31'
	and GroupId = 1


-- Affiliate_N88
update Affiliate_N88.dbo.DeductionSetting with (rowlock, updlock)
set DeductedPercentage = CASE GroupId
							WHEN 1 THEN 0.12
							WHEN 2 THEN 0.17
							WHEN 3 THEN 0.17
							WHEN 4 THEN 0
							WHEN 5 THEN 0.1
							WHEN 6 THEN 0.12
							WHEN 7 THEN 0.12
							ELSE DeductedPercentage END
	, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1

update Affiliate_N88.dbo.DeductionSettingHistory with (rowlock, updlock)
set DeductedPercentage = CASE GroupId
							WHEN 1 THEN 0.12
							WHEN 2 THEN 0.17
							WHEN 3 THEN 0.17
							WHEN 4 THEN 0
							WHEN 5 THEN 0.1
							WHEN 6 THEN 0.12
							WHEN 7 THEN 0.12
							ELSE DeductedPercentage END
	, DeductedAmount = 0, IsDeductedPercent = 1
where DeductionId = 10
	and GroupProductId = 1
	and MonthDate >= '2021-01-31'