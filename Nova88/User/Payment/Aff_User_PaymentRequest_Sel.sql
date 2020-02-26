/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_PaymentRequest_Sel]
	@AffID				INT,
	@Year				INT,
	@PreferredPayment	VARCHAR(20) OUTPUT,
	@BalBroughtForward	MONEY OUTPUT,	
	@MinAmount			MONEY OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: User site - Payment Request - Get payment list

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Add @MonthDate - filter Requested Date (TransDate) by Year [RedmineID: #102322]
*/

BEGIN
	SET NOCOUNT ON

	-- Preferred Payment
	SELECT @PreferredPayment = PreferredPayment
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE AffID = @AffID

	-- Min Amount
	DECLARE @currencyName VARCHAR(5)
	SELECT @currencyName = e.currency
	FROM dbo.AffInfo a WITH (NOLOCK)
		INNER JOIN dbo.Exchange_Current e WITH (NOLOCK) ON e.ExchangeID = a.currency
	WHERE a.AffID = @AffId

	SELECT @MinAmount = SValue
	FROM SystemSettings WITH (NOLOCK)
	WHERE SName = 'AFF_Min' + @PreferredPayment + @currencyName

	-- Get Balance Brought Forward
	SELECT @BalBroughtForward = ISNULL(BalBroughtForward, 0) FROM dbo.Aff_f_GetBalBroughtForward(@AffID)

	-- Payment list
	DECLARE @BeginYear SMALLDATETIME, @EndYear SMALLDATETIME
	SELECT  @BeginYear	= CONVERT(VARCHAR(4), @Year) + '-01-01'
	SELECT  @EndYear	= CONVERT(VARCHAR(4), @Year) + '-12-31'

	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)

	SELECT  @BeginYear = CASE WHEN @BeginYear < @MinReportDate THEN @MinReportDate ELSE @BeginYear END

	SELECT t.TransID, p.RefID, p.TransDate, p.CompletedDate, p.Status, ABS(p.Amount) AS Amount, p.AffDesc
	FROM dbo.AffPayout p WITH (NOLOCK)
		INNER JOIN dbo.AffTrans t WITH (NOLOCK) ON p.RefID = t.RefID
	WHERE p.AffID = @AffID
		AND t.TransType = 202 -- Payment
		AND p.TransDate BETWEEN @BeginYear AND @EndYear
	ORDER BY p.RefID DESC
END
GO