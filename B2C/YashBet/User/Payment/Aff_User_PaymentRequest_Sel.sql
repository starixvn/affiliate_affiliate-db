/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_PaymentRequest_Sel]
	@AffID				INT,
	@Year				INT,
	@PreferredPayment	VARCHAR(20) OUTPUT,
	@BalBroughtForward	MONEY OUTPUT,	
	@MinAmount			MONEY OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Payment Request - Get payment list

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	-- Preferred Payment
	SELECT @PreferredPayment = PreferredPayment
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE AffID = @AffID

	-- Min Amount
	DECLARE @currencyName VARCHAR(5)
	SELECT @currencyName = a.CurrencyName
	FROM dbo.AffInfo a WITH (NOLOCK)
	WHERE a.AffID = @AffId

	SELECT @MinAmount = SValue
	FROM SystemSettings WITH (NOLOCK)
	WHERE SName = 'Payment_MinAmount'

	-- Get Balance Brought Forward
	SELECT @BalBroughtForward = ISNULL(BalBroughtForward, 0) FROM dbo.Aff_f_GetBalBroughtForward(@AffID)

	-- Payment list
	DECLARE @FromBeginYear SMALLDATETIME, @ToNextYear SMALLDATETIME
	SELECT  @FromBeginYear = CONVERT(VARCHAR(4), @Year) + '-01-01'
	SELECT  @ToNextYear	= DATEADD(YEAR, 1, @FromBeginYear)

	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = dbo.Aff_f_GetMinReportDate(@AffId)

	SELECT  @FromBeginYear = CASE WHEN @FromBeginYear < @MinReportDate THEN @MinReportDate ELSE @FromBeginYear END

	SELECT
		t.TransID
		,p.RefID
		,p.TransDate
		,p.CompletedDate
		,CASE p.Status
			WHEN 'Pending' THEN 'Processing'
			ELSE p.Status END AS Status
		,ABS(p.Amount) AS Amount
		,p.AffDesc
	FROM dbo.AffPayout p WITH (NOLOCK)
		INNER JOIN dbo.AffTrans t WITH (NOLOCK) ON p.RefID = t.RefID
	WHERE p.AffID = @AffID
		AND t.TransType = 202 -- Payment
		AND p.TransDate >= @FromBeginYear AND p.TransDate < @ToNextYear
	ORDER BY p.RefID DESC
END
GO