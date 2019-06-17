/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateOnlineList_Sel]
	@AffId		INT = NULL,
	@Username	NVARCHAR(50) = NULL
AS

/*
	Creator: 20190614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task:
		Admin - Customer - Left menu - Current Online List
	
	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
*/

BEGIN
	SET NOCOUNT ON

	IF @AffId IS NULL
	BEGIN
		-- Search by username
		SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE UserName = @Username

		-- Search by username2
		IF @AffId IS NULL
			SELECT @AffId = AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE UserName2 = @Username
	END

	-- Online List
	SELECT IP, reload_time AS ReloadTime
	FROM dbo.On_User WITH (NOLOCK)
	WHERE custid = @AffId
	ORDER BY reload_time DESC
END
GO