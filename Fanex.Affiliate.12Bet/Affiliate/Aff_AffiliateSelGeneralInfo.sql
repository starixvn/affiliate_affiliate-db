/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_AffiliateSelGeneralInfo]
	@Username NVARCHAR(50),
	@IsCasino BIT = 0 OUTPUT
AS

/*
	Created: 20090730@Peter
	Task : Select affiliate info for left panel
	DB: DBAFF12BET.Affiliate_12BET

	Revisions:
		- 20090823@Peter:
			1. Rewrite the sp for new DB DB052.Affiliate_12BET
			2. Remove the theory of pending commission and CurrCommEarning
			3. Get PreferredPayment to check approve
		- 20090823@Peter : Move table on_user to Affiliate_12Bet DB
		- 20180601@Percy: Add ContactApps [RedmineID: #87923]

	Param's Explanation:
		• @Username : Affiliate username
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @AffID INT
	SELECT  @AffID = AffID FROM dbo.AffInfo WITH(NOLOCK) WHERE username = @Username

	IF @AffID IS NULL
	BEGIN
		SELECT @AffID = AffID FROM dbo.AffInfo WITH(NOLOCK) WHERE username2 = @Username
		
		IF @AffID IS NULL
			RETURN
	END
	
	SELECT 	--Get affiliate info
		IsClosed AS closed,
		IsLocked, 	
		a.Username,	
		Username2,	
		a.AffID,
		firstname,
		lastname,
		gender,
		email,
		phone,
		ContactApps,
		siteurl,
		lastLoginDate,
		lastLoginIP AS lastloginip,	
		PreferredLanguage,
		PreferredPayment,
		Player_Username,
		status,
		MailOption,--Johnny Add to send relevant email format.
		ISNULL(c.groupname,'') AS groupname,	
		ISNULL(c.groupid,-1) AS groupid,
		ISNULL(dbo.Aff_GetAffBalance(@AffId), 0) AS BalBroughtForward,
		AffType
	FROM AffInfo a WITH(NOLOCK)
		INNER JOIN AffDetail d WITH(NOLOCK) ON a.AffID = d.AffID
		LEFT JOIN CommGroup c WITH(NOLOCK) ON c.groupid = a.groupid
	WHERE a.AffID=@AffID 	

	-- Online List (for left menu)
	SELECT IP, reload_time
	FROM dbo.On_User WITH (NOLOCK)
	WHERE custid = @AffId
	ORDER BY reload_time DESC

	-- Is Casino
	IF EXISTS (SELECT 1 FROM dbo.CommonSettings WITH (NOLOCK) WHERE [Type] = '12betcasino' AND CName = @Username)
		SELECT @IsCasino = 1
	ELSE
		SELECT @IsCasino = 0
END
GO