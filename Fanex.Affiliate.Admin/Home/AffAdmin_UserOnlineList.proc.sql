ALTER Procedure [dbo].[AffAdmin_UserOnlineList]       
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
       
Param's Explanation:      
 - PageSize: the selected page size on webpage      
 - PageIndex: the index of selected page in paging structure      
 - TotalPages: the number of pages with the pagesize returned from DB      
 - @IsIt: Show It account or not  
*/      
BEGIN        
SET NOCOUNT ON      
declare @startNum int, @endNum int, @GroupIT int    
declare @Table table([No] int IDENTITY(1,1), UserName varchar(50),LoggedIn datetime,LastRequest datetime,IP varchar(20),Role varchar(20))       
    
Select @GroupIt = [dbo].[Aff_Con_GetGroupItID]()    
        
insert into @Table(UserName,LoggedIn,LastRequest,IP,Role)       
select UserName,LoggedIn,LastRequest,IP,RoleName      
from      
(      
 (select au.username as UserName, au.lastlogged as LoggedIn, o.reload_time as LastRequest, o.IP as IP, 'Admin' as RoleName       
 from ON_USER o with(nolock)             
  inner join  dbo.AdminUser au with(nolock) on au.custid=o.custid       
 where o.subaccid = 6 and o.iskickedout=0    
   and (case when @IsIT = 1 then 1     
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
select @endNum = (@PageIndex)*@PageSize;      
select @startNum = @endNum - @PageSize + 1;      
select * from @table where [no] between @startNum and @endNum order by Role,LastRequest desc ,UserName       
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end      
    
    
END 

GO
GRANT EXECUTE ON [dbo].[AffAdmin_UserOnlineList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_UserOnlineList] TO [vnteam]