ALTER Procedure [dbo].[AffAdmin_UserOnlineList]
 @LicenseeID INT,       
 @PageSize int=50,        
 @PageIndex int=1,      
 @IsIt bit = 0,      
 @TotalPages int=0 OUTPUT,      
 @NRows int=0 OUTPUT     
AS      
/*Created: 20130807@Johnny      
Task : Select all affs and admins currently logging on affliate system      
DB: DB052.Affiliate_MYM      
      
Revisions:
	- 20130807@Johnny: initialize      
	- 20131225@Bobby: update sorting result
	- 20151117@Victor: Implement SSO from Internal Admin to Affiliate Admin site
       
Param's Explanation:      
 - PageSize: the selected page size on webpage      
 - PageIndex: the index of selected page in paging structure      
 - TotalPages: the number of pages with the pagesize returned from DB      
 - @IsIt: Show It account or not  
*/      
BEGIN        
	SET NOCOUNT ON      
	declare @startNum int, @endNum int, @GroupIT int    
	declare @Table table(UserName varchar(50),LoggedIn datetime,LastRequest datetime,IP varchar(20),Role varchar(20))       
    
	Select @GroupIt = [dbo].AffAdmin_f_GetITGroupID(@LicenseeID)    
        
	insert into @Table(UserName,LoggedIn,LastRequest,IP,Role)       
	select UserName,LoggedIn,LastRequest,IP,RoleName      
	from      
	(      
	 (select au.username as UserName, /*au.lastlogged*/'' as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Admin' as RoleName       
	 from dbo.AffAdmin_f_OnUser_Select(0) o
	  inner join  dbo.AffAdmin_f_AdminUserInfo_Select('', @LicenseeID) au on au.userid=o.custid       
	 where (case when @IsIT = 1 then 1     
		when GroupID = @GroupIt then 0    
		else 1 end) = 1    
	 )          
	 union all       
	 (select aff.username as UserName, aff.lastlogindate as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Affiliate' as RoleName      
	 from ON_USER o with(nolock)      
	 inner join dbo.affdetail aff with(nolock) on aff.affid=o.custid  and o.iskickedout=0)      
	) x          
	--order by       

	select @NRows=@@ROWCOUNT      
	select @startNum = (@PageIndex-1)*@PageSize;  
	select @endNum = (@startNum + @PageSize);      

	;WITH SortedTable AS
	(	
		SELECT *, 
			ROW_NUMBER() OVER (ORDER BY  [Role],LastRequest desc ,UserName ) AS RowNo
		FROM @table
	)
	select * from SortedTable 
	where RowNo between @startNum and @endNum 

	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end      
        
END 

GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserOnlineList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserOnlineList] TO [vnteam]