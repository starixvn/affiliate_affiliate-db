/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Check_AffBelongToUser]
	@UserId			INT
	,@AffId			INT
	,@IsBelongTo	BIT = 0 OUTPUT
AS

/*
	Created: 20200731@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Core function - Check affiliate is belong to user or not

	Revisions:
		- 20200731@Percy: Initialize SP [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SET @IsBelongTo = 0

	-- Check market
	DECLARE @PreferredLanguage NVARCHAR(10)
	SELECT  @PreferredLanguage = PreferredLanguage FROM dbo.AffDetail WITH (NOLOCK) WHERE AffId = @AffId

	IF @@ROWCOUNT = 0
		RETURN
	
	IF EXISTS (SELECT 1 FROM dbo.UserMarket WITH (NOLOCK) WHERE CustId = @UserId AND MarketId = @PreferredLanguage)
		SET @IsBelongTo = 1
END
GO