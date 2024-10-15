/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_UserOnlineList]
	@LicenseeID		INT,
	@UserCurrencies	VARCHAR(MAX) = '',
	@PageSize		INT = 50,        
	@PageIndex		INT = 1,      
	@IsIt			BIT = 0,      
	@TotalPages		INT = 0 OUTPUT,      
	@NRows			INT = 0 OUTPUT
AS

/*
	Created: 20130807@Johnny
	Task : Select all affs and admins currently logging on affliate system
	DB: DBAFF.Affiliate_XXX
      
	Revisions:
		- 20130807@Johnny: initialize
		- 20131225@Bobby: update sorting result
		- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20151207@Francis: Revise sp to return only affiliate under user's currency permissions
		- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_OnUser_Select
							AffAdmin_f_AdminUserInfo_Select
		- 20220518@Malcolm: fix error can not get UserName, LoggedIn, LastRequest, IP, Role [RedmineId: #172945]
		- 20240813@Sally: Remove linked server to DBCust [RedmineID: #206891]


	Param's Explanation:
	 - PageSize: the selected page size on webpage
	 - PageIndex: the index of selected page in paging structure
	 - TotalPages: the number of pages with the pagesize returned from DB
	 - @IsIt: Show It account or not
*/

BEGIN        
	SET NOCOUNT ON;
	
	DECLARE @startNum INT, @endNum INT
	DECLARE @Table TABLE (UserName VARCHAR(50), LoggedIn DATETIME, LastRequest DATETIME, [IP] VARCHAR(20), [Role] VARCHAR(20))

	DECLARE @GroupIT INT
	SELECT	@GroupIT = GroupID 
	FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID)
	
	INSERT INTO @Table (UserName, LoggedIn, LastRequest, IP, Role)
	SELECT au.username AS UserName, au.LastLogin AS LoggedIn, o.reload_time AS LastRequest, o.[IP] AS IP, 'Admin' AS RoleName 
	FROM bodb_Licensee.dbo.AffAdmin_f_OnUser_Select(0) o 
		INNER JOIN bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) au ON au.userid = o.custid
	WHERE 1 = CASE WHEN  @IsIt = 1 THEN 1 
					WHEN GroupId = @GroupIt THEN 0 ELSE 1 END				
      	
	IF (@IsIt = 1)
	BEGIN     
		INSERT INTO @Table (UserName, LoggedIn, LastRequest, IP, Role)
		SELECT aff.username as UserName, aff.lastlogindate AS LoggedIn, o.reload_time AS LastRequest, o.IP AS IP, 'Affiliate' AS RoleName      
		FROM dbo.ON_USER o WITH (NOLOCK)      
			INNER JOIN dbo.affdetail aff WITH (NOLOCK) ON aff.affid = o.custid AND o.iskickedout = 0 
	END
	ELSE
	BEGIN
		INSERT INTO @Table (UserName, LoggedIn, LastRequest, IP, Role)
		SELECT aff.username AS UserName, aff.lastlogindate AS LoggedIn, o.reload_time AS LastRequest, o.IP AS IP, 'Affiliate' AS RoleName      
		FROM dbo.ON_USER o WITH (NOLOCK)      
			INNER JOIN dbo.affdetail aff WITH (NOLOCK) ON aff.affid = o.custid AND o.iskickedout = 0 
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON aff.AffID = ai.AffID
		WHERE ai.Currency IN (SELECT CONVERT(INT, value) FROM STRING_SPLIT(@UserCurrencies, ','))
	END
	
	SELECT @NRows = @@ROWCOUNT      
	SELECT @startNum = (@PageIndex - 1) * @PageSize;  
	SELECT @endNum	 = (@startNum + @PageSize);      

	;WITH SortedTable AS
	(	
		SELECT UserName, LoggedIn, LastRequest, IP, Role, 
			ROW_NUMBER() OVER (ORDER BY [Role], LastRequest DESC, UserName) AS RowNo
		FROM @table
	)
	SELECT UserName, LoggedIn, LastRequest, IP, Role, RowNo
	FROM SortedTable 
	WHERE RowNo BETWEEN @startNum AND @endNum 

	SELECT @TotalPages = @NRows/@PageSize + CASE WHEN @NRows%@PageSize > 0 THEN 1 ELSE 0 END      

END
 

