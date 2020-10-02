/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_UserOnlineList]
	@PageSize	INT = 50
	,@PageIndex	INT = 1
	,@NRows		INT = 0 OUTPUT
AS

/*
	Created: 20090828@Bryan
	DB: DBAFF12BET-Affiliate_12BET
	Task: Select all affs and admins currently logging on affliate system
	
	Revisions:
		- 20090829@Bryan: initialize
		- 20110610@Johnny: move to db Affiliate_12BET
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN		
	SET NOCOUNT ON

	DECLARE @On_Users TABLE
	(
		RowId			INT IDENTITY (1, 1)
		,UserName		VARCHAR(50)
		,LoggedIn		DATETIME
		,LastRequest	DATETIME
		,IP				VARCHAR(20)
		,RoleName		VARCHAR(20)
	)
	INSERT INTO @On_Users (UserName, LoggedIn, LastRequest, IP, RoleName) 
	SELECT u.UserName, u.LastLoginDate, o.reload_time, o.IP, u.RoleName
	FROM dbo.On_User o WITH (NOLOCK)
		CROSS APPLY (
			SELECT u.UserName, u.LastLoginDate, 'Admin' AS RoleName
			FROM dbo.Users u WITH (NOLOCK)
			WHERE u.CustId = o.CustId
			UNION ALL
			SELECT a.UserName, a.LastLoginDate, 'Aff' AS RoleName
			FROM dbo.AffDetail a WITH (NOLOCK)
			WHERE a.AffId = o.CustId
		) u
	WHERE o.IsKickedOut = 0
	ORDER BY o.reload_time DESC

	SELECT @NRows = @@ROWCOUNT

	DECLARE @RowStart INT, @RowEnd INT
	SELECT  @RowEnd = @PageIndex * @PageSize
	SELECT  @RowStart = @RowEnd - @PageSize + 1

	SELECT RowId, UserName, LoggedIn, LastRequest, IP, RoleName
	FROM @On_Users
	WHERE RowId BETWEEN @RowStart AND @RowEnd
	ORDER BY RowId
END
GO