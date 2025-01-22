/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_UserOnlineList] 
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task:

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/
BEGIN		
	SET NOCOUNT ON
	DECLARE @startNum INT
		   ,@endNum INT

	DECLARE @Table TABLE(
		[No]		INT IDENTITY (1, 1)
	   ,UserName	VARCHAR(50)
	   ,LoggedIn	DATETIME
	   ,LastRequest DATETIME
	   ,IP			VARCHAR(20)
	   ,RoleName	VARCHAR(20)
	)
	INSERT INTO @Table (UserName, LoggedIn, LastRequest, IP, RoleName)
	SELECT UserName
		,LoggedIn
		,LastRequest
		,IP
		,RoleName
	FROM (
		(SELECT
			au.UserName AS UserName
			,au.lastlogged AS LoggedIn
			,o.reload_time AS LastRequest
			,o.IP AS IP
			,'Admin' AS RoleName
		FROM On_User o WITH (NOLOCK)
		INNER JOIN Affiliate_User au WITH (NOLOCK)
			ON au.CustId = o.CustId
			AND o.iskickedout = 0)
		UNION ALL
		(SELECT
			aff.UserName AS UserName
			,aff.lastlogindate AS LoggedIn
			,o.reload_time AS LastRequest
			,o.IP AS IP
			,'Aff' AS RoleName
		FROM On_User o WITH (NOLOCK)
		INNER JOIN AffDetail aff WITH (NOLOCK)
			ON aff.AffId = o.CustId
			AND o.iskickedout = 0)
	) x
	ORDER BY LastRequest ASC

	SELECT @NRows = @@rowcount
	SELECT @endNum = (@PageIndex) * @PageSize;
	SELECT @startNum = @endNum - @PageSize + 1;

	SELECT*
	FROM @Table
	WHERE [No] BETWEEN @startNum AND @endNum
	ORDER BY RoleName, UserName

	SELECT @TotalPages = @NRows / @PageSize + CASE WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0 END
END
GO