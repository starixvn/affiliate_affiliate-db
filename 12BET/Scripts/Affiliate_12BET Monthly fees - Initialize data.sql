USE [Affiliate_12BET]
GO

/*
	Created: 20180917@Percy
	DB: DBAFF12BET - Affiliate_12BET
	Task: Add new table for monthly fees
*/

DECLARE @MonthDate SMALLDATETIME = '2018-08-31'


CREATE TABLE #rptAffDeduction
(
	MonthDate		SMALLDATETIME,
	AffId			INT,
	GroupId			INT,
	ProductId		INT,
	GroupProductId	TINYINT,
	DeductionId		INT,
	Amount			MONEY
)

CREATE TABLE #Setting
(
	AffId				INT,
	GroupId				INT,
	ProductId			INT,
	GroupProductId		TINYINT,
	DeductionId			TINYINT,
	DeductedPercentage	DECIMAL(9,8)
)
	
INSERT INTO #Setting
(
	AffId,
	GroupId,
	ProductId,
	GroupProductId,
	DeductionId,
	DeductedPercentage
)
SELECT
	agh.AffId,
	agh.GroupId,
	dsh.ProductId,
	dsh.GroupProductId,
	dsh.DeductionId,
	dsh.DeductedPercentage
FROM dbo.AffGroupHistory agh WITH (NOLOCK)
	INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
WHERE agh.AffId IN (927841,92040664,92040667) AND agh.MonthDate = @MonthDate

-- Data
CREATE TABLE #Data
(
	AffId			INT,
	GroupId			INT,
	ProductId		INT,
	Winloss			MONEY,
	Deposit			MONEY,
	Withdrawal		MONEY
)

INSERT INTO #Data
(
	AffId,
	GroupId,
	ProductId,
	Winloss,
	Deposit,
	Withdrawal
)
SELECT
	AffId,
	GroupId,
	ProductId,
	Winloss,
	Deposit,
	Withdrawal
FROM dbo.rptAffCommission WITH (NOLOCK)
WHERE AffId IN (927841,92040664,92040667) AND MonthDate = @MonthDate

-- import data
INSERT INTO #rptAffDeduction
(
	MonthDate,
	AffId,
	GroupId,
	ProductId,
	GroupProductId,
	DeductionId,
	Amount
)
SELECT
	@MonthDate,
	d.AffId,
	d.GroupId,
	d.ProductId,
	s.GroupProductId,
	s.DeductionId,
	(CASE s.DeductionId WHEN 12 THEN d.Deposit + d.Withdrawal ELSE d.Winloss END) * s.DeductedPercentage
FROM #Data d
	INNER JOIN #Setting s ON d.AffId = s.AffId AND d.GroupId = s.GroupId AND d.ProductId = s.ProductId
WHERE (CASE s.DeductionId WHEN 12 THEN d.Deposit + d.Withdrawal ELSE d.Winloss END) * s.DeductedPercentage <> 0

;WITH CTE_PlatFormFee AS
(
	SELECT AffId, GroupId, SUM(Amount) AS Amount
	FROM #rptAffDeduction
	WHERE DeductionId = 10
	GROUP BY AffId, GroupId, GroupProductId
)
INSERT INTO #rptAffDeduction
(
	MonthDate,
	AffId,
	GroupId,
	ProductId,
	GroupProductId,
	DeductionId,
	Amount
)
SELECT
	@MonthDate,
	AffId,
	GroupId,
	0 AS ProductId,
	1 AS GroupProductId,
	10 AS DeductionId,
	SUM(ABS(Amount)) AS Amount
FROM CTE_PlatFormFee
GROUP BY
	AffId,
	GroupId

INSERT INTO dbo.rptAffDeduction (MonthDate,AffId,GroupId,ProductId,GroupProductId,DeductionId,Amount)
SELECT @MonthDate,AffId,GroupId,ProductId,GroupProductId,DeductionId,Amount
FROM #rptAffDeduction
ORDER BY AffId, DeductionId

DROP TABLE #Data
DROP TABLE #Setting
DROP TABLE #rptAffDeduction