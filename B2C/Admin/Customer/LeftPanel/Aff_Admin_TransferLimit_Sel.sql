/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_TransferLimit_Sel]
	@AffId INT
AS

/*
	Creator: 20211005@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Admin site - Customer - Left menu - Transfer Limit
	
	Revisions:
		- 20211005@Percy: Initialize SP [RedmineID: #153227]
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