/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_TransferLimit_Sel]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Admin site - Customer - Left menu - Transfer Limit
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT
		Player_CustId			AS PlayerCustId
		,Player_Username		AS PlayerUsername
		,Player_CurrencyCode	AS PlayerCurrency
		,TransferLimit
		,CONVERT(BIT, ISNULL(DisabledTransfer, 0)) AS DisabledTransfer
	FROM dbo.AffDetail WITH (NOLOCK)
	WHERE AffId = @AffId
END
GO