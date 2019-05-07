/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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

	Param's Explanation:
	 - PageSize: the selected page size on webpage
	 - PageIndex: the index of selected page in paging structure
	 - TotalPages: the number of pages with the pagesize returned from DB
	 - @IsIt: Show It account or not
*/

BEGIN        
	SET NOCOUNT ON      
	
	declare @startNum int, @endNum int
	declare @Table table (UserName varchar(50),LoggedIn datetime,LastRequest datetime,IP varchar(20),Role varchar(20))
	
	DECLARE @sql NVARCHAR(MAX)

	DECLARE @tblGroupIT TABLE (GroupID INT)

	SELECT  @sql = 'SELECT GroupID FROM OPENQUERY(DBCUST, ''SELECT GroupID FROM bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select(' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'
	
	INSERT INTO @tblGroupIT (GroupID)
	EXEC (@sql)

	DECLARE @GroupIT INT
	SELECT	@GroupIT = GroupID FROM @tblGroupIT
	
	SELECT  @sql = 'SELECT au.username AS UserName, au.LastLogin AS LoggedIn, o.reload_time AS LastRequest, o.IP AS IP, ''Admin'' AS RoleName
					FROM OPENQUERY(DBCUST,
							''SELECT au.username AS UserName, au.LastLogin AS LoggedIn, o.reload_time AS LastRequest, o.IP AS IP, ''Admin'' AS RoleName
							FROM bodb_Licensee.dbo.AffAdmin_f_OnUser_Select(0) o
								INNER JOIN bodb_Licensee.dbo.AffAdmin_f_AdminUserInfo_Select('''''''',' + CONVERT(VARCHAR(10), @LicenseeID) + ') au
									ON au.userid = o.custid
							WHERE 1 = CASE WHEN ' + CONVERT(VARCHAR(1), @IsIt) + ' = 1 THEN 1 WHEN GroupId = ' + CONVERT(VARCHAR(1), @GroupIt) + ' THEN 0 ELSE 1 END'')'
        
	INSERT INTO @Table(UserName,LoggedIn,LastRequest,IP,Role)       
	EXEC (@sql)
	
	if (@IsIt = 1)
	begin     
		insert into @Table(UserName,LoggedIn,LastRequest,IP,Role)       
		select aff.username as UserName, aff.lastlogindate as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Affiliate' as RoleName      
		from dbo.ON_USER o with (nolock)      
		inner join dbo.affdetail aff with (nolock) on aff.affid = o.custid  and o.iskickedout = 0 
	end
	else
	begin
		insert into @Table(UserName,LoggedIn,LastRequest,IP,Role)       
		select aff.username as UserName, aff.lastlogindate as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Affiliate' as RoleName      
		from dbo.ON_USER o with (nolock)      
		inner join dbo.affdetail aff with (nolock) on aff.affid = o.custid and o.iskickedout = 0 
		inner join dbo.AffInfo ai with (nolock) on aff.AffID = ai.AffID
		where ai.Currency in (select convert(int, val) from dbo.strSplit(@UserCurrencies, ','))
	end
	
	select @NRows=@@ROWCOUNT      
	select @startNum = (@PageIndex-1)*@PageSize;  
	select @endNum = (@startNum + @PageSize);      

	;WITH SortedTable AS
	(	
		SELECT UserName,LoggedIn,LastRequest,IP,Role, 
			ROW_NUMBER() OVER (ORDER BY  [Role],LastRequest desc ,UserName ) AS RowNo
		FROM @table
	)
	select UserName,LoggedIn,LastRequest,IP,Role,RowNo
	from SortedTable 
	where RowNo between @startNum and @endNum 

	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end      
END
GO