/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_PaymentRequest_Sel]
	@AffID				INT,
	@PreferredPayment	VARCHAR(20) OUTPUT,
	@BalBroughtForward	MONEY OUTPUT,	
	@MinAmount			MONEY OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User - Payment Request - Get payment list

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

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

	--Get Balance Brought Forward
	SELECT @BalBroughtForward = dbo.Aff_GetAffBalance(@AffID)

	SELECT t.TransID, p.RefID, p.TransDate, p.CompletedDate, p.Status, ABS(p.Amount) AS Amount, p.AffDesc
	FROM dbo.AffPayout p WITH (NOLOCK)
		INNER JOIN dbo.AffTrans t WITH (NOLOCK) ON p.RefID = t.RefID
	WHERE p.AffID = @AffID
	ORDER BY p.RefID DESC
END
GO