ALTER PROCEDURE [dbo].[Aff_UserOnlineList] 
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT
AS
/*Created: 20090828@Bryan
Task : Select all affs and admins currently logging on affliate system
DB: DB052.Affiliate_12Bet

Revisions:- 20090829@Bryan initialize

	- 20110610@Johnny: move  to db Affiliate_12BET
Param's Explanation:
	- PageSize: the selected page size on webpage
	- PageIndex: the index of selected page in paging structure
	- TotalPages: the number of pages with the pagesize returned from DB
	- NRows: total records found
*/
BEGIN		
	SET NOCOUNT ON
	declare @startNum int, @endNum int 
	declare @Table table([No] int IDENTITY(1,1), UserName varchar(50),LoggedIn datetime,LastRequest datetime,IP varchar(20),RoleName varchar(20)) 
	insert into @Table(UserName,LoggedIn,LastRequest,IP,RoleName) 
		select UserName,LoggedIn,LastRequest,IP,RoleName
		from
		 (
			(select au.username as UserName, au.lastlogged as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Admin' as RoleName 
			   from ON_USER o with(nolock)				   
				   inner join Affiliate_User au with(nolock) on au.custid=o.custid  and o.iskickedout=0 )
			union all 
			(select aff.username as UserName, aff.lastlogindate as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Aff' as RoleName
			from ON_USER o with(nolock)
				inner join affdetail aff with(nolock) on aff.affid=o.custid  and o.iskickedout=0)
		 )x    
	order by LastRequest asc  
	select @NRows=@@ROWCOUNT
	select @endNum = (@PageIndex)*@PageSize;
	select @startNum = @endNum - @PageSize + 1;
	select * from @table where [no] between @startNum and @endNum order by RoleName,UserName
	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end
END


GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_UserOnlineList] TO [vnteam]