/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateOnlineList_Sel]
	@AffId		INT = NULL,
	@Username	NVARCHAR(50) = ''
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:
		Admin - Customer - Left menu - Current Online List
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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