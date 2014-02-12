  
ALTER Procedure [dbo].[Aff_CommGroupSel]  
 @GroupName nvarchar(100) = '',  
 @Currency varchar(5)='',  
 @FromDate datetime =null,  
 @Todate datetime=null,  
 @TotalNoneGroup int=0 OUTPUT,  
 @PageSize int=50,  
 @PageIndex int=1 OUTPUT,  
 @TotalPages int=0 OUTPUT,  
 @NRows int=0 OUTPUT  
AS  
  
/*  
Created: 20090719@DungTong  
Task : Search a Commission Group (paging)  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
*/  
SET NOCOUNT ON  
select @Currency='%' + Coalesce(@Currency, '') + '%'       
if (isnull(@GroupName,'')='' or lower(@GroupName)='[none]')  
begin  
 select @TotalNoneGroup=count(1)  
 from AffInfo a with (nolock)  
      inner join CommGroup c with (nolock) on c.GroupID=a.GroupID  
 where c.GroupID>1000 and c.IsDeleted=0  and c.Currency like @Currency    
end   
if(lower(@GroupName)='[none]')  
begin    
   return  
end  
  
select @GroupName = '%' + @GroupName + '%'  
---CommGroup Detail va SportName se duoc cache tren web server dung co che notification  
DECLARE @RowStart int, @RowEnd int,@AffiliateID int  
  
  
  
select @Nrows=count(1)  
from CommGroup with (nolock)  
where GroupID between 101 and 1000 and GroupName like @GroupName and IsDeleted = 0 and Currency like @Currency   
      and (  
          case when @FromDate is null or @ToDate is null then 1  
                when CreatedDate between @FromDate and @ToDate then 1  
                else 0  
          end       
      )=1  
        
 if(isnull(@NRows,0)=0 or (@NRows>@PageSize and @PageSize>5000) or @PageIndex<0 or @PageSize<0)  
   return   
  
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end  
if(@PageIndex>@TotalPages)  
  select @PageIndex=@TotalPages  
select @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1            
  
declare @Group table(GroupID int primary key,GroupName nvarchar(100),  
      Description nvarchar(100),Creator int,CreatedDate datetime,  
      ExchangeID smallint,Currency varchar(5),QualifiedAmount money,NoAff int)  
  
insert into @Group(GroupID,GroupName,Description,Creator,CreatedDate,ExchangeID,Currency,QualifiedAmount)  
 select GroupID,GroupName,Description,Creator,CreatedDate,ExchangeID,Currency,QualifiedAmount  
  from (  
    SELECT GroupID,GroupName,Description,CommGroup.Creator,CommGroup.CreatedDate,ExchangeID,e.Code as Currency,QualifiedAmount      
      ,ROW_NUMBER() OVER(ORDER BY GroupID) AS TheCount  
     from CommGroup with (nolock)            
     inner join dbo.Exchange e on CommGroup.Currency = e.ExchangeID  
      where GroupID between 101 and 1000 and  GroupName like @GroupName and IsDeleted = 0 and CommGroup.Currency like @Currency  
     and (  
      case when @FromDate is null or @ToDate is null then 1  
      when CommGroup.CreatedDate between @FromDate and @ToDate then 1  
      else 0  
      end       
         ) = 1  
         ) x  
     where x.TheCount between @RowStart and @RowEnd   
 Update t  
 set t.NoAff=(select sum(1) from AffInfo i with (nolock) where i.GroupID=t.GroupID)  
 from @Group t  
   
 Select top(100)  DTypeID,ProductID,DTypeName,DTypeDesc,DeductedPercentage   
 from DeductionType (nolock)  
   
Select DeductionID,GroupID,DeductedPercentage   
from DeductionSetting (nolock)  
where GroupID in (select GroupID from @Group)   
   
 select g.GroupID,g.GroupName,g.Description,isnull(i.username,'System') as Creator,g.CreatedDate,isnull(g.NoAff,0) as NoOfAffiliate,  
  g.Currency,g.QualifiedAmount  
  ,(case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID)   
     or Exists(select top(1) 1 from AffInfo ai (nolock) where ai.GroupID=g.GroupID)  then 0 else 1 end) as IsAllowedToDelete   
 from @Group g   
      left join AdminUser i with (nolock) on i.custid=g.Creator  
   
  
select   
 g.GroupId,   
    g.ProductID,  
 s.ProductName,  
 g.TierID,  
 g.MinAmount,  
 g.MaxAmount,  
 g.MinQM,  
 g.MaxQM,  
 g.Commission   
from GroupSetting g with (nolock)  
     inner join Product s with (nolock) on s.ProductID=g.ProductID  
where g.GroupID in (  
  select GroupID from @Group  
   )  
  
  
  

GO
GRANT EXECUTE ON [dbo].[Aff_CommGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CommGroupSel] TO [vnteam]