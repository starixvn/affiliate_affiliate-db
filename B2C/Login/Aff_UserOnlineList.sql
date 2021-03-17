/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_UserOnlineList] 
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT
AS
/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Original:

	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
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
