ALTER Procedure [dbo].[AffAdmin_CommGroupSel]
	@GroupName nvarchar(100) = '',
	@Currencies varchar(1000)='',
	@Date datetime,	
	@UserId int,
	@GroupID int = 0,
	@GroupIDList varchar(1000) = '' OUTPUT,	
	@PageSize int=50,
	@PageIndex int=1 OUTPUT,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

/*
Created: 20090719@DungTong
Task : Search a Commission Group (paging)
DB: DB052.Affiliate_MYM
Original:

Revisions:
	- 20130913@Joseph: new version
	- 20131121@Joseph: filter by TestLevel
*/
SET NOCOUNT ON

-- Test Account
DECLARE @IsITAdmin BIT
SELECT @IsITAdmin = CASE GroupID WHEN 2 THEN 1 ELSE 0 END FROM AdminUser WHERE custid = @UserId

SELECT AttributeID as CurrencyID INTO #tmpCurrency
FROM dbo.Aff_f_GetCurrencybyUser (@UserId,1)
-- Insert statements for procedure here  
 declare @TblCurrency table (val nvarchar( 6) )
if @Currencies != 'All'
begin
	
	insert into @TblCurrency 
	select c.val from [dbo].[strSplit] ( @Currencies, ',' ) c
	inner join #tmpCurrency t on c.val = t.CurrencyID
	-- NoCommission group
	if (select count(1) from @TblCurrency) > 0
		insert into @TblCurrency values(0)
	
end

select @GroupName = '%' + Coalesce(@GroupName,'') + '%'
---CommGroup Detail va SportName se duoc cache tren web server dung co che notification
DECLARE @RowStart int, @RowEnd int,@AffiliateID int

if DateDiff(m,CURRENT_TIMESTAMP,@Date) >= 0
	select @Nrows=count(1)
	from CommGroup with (nolock)
	where GroupName like @GroupName and IsDeleted = 0 
	and (@Currencies = 'All' or (@Currencies is not null and Currency in (select val from @TblCurrency)))
else
	select @Nrows=count(1)
	from CommGroupHistory with (nolock)
	where GroupName like @GroupName and IsDeleted = 0 and (@Currencies = 'All' or (@Currencies is not null and Currency in (select val from @TblCurrency)))
	and DateDiff(m,@Date,MonthDate) = 0
-- if(isnull(@NRows,0)=0 or (@NRows>@PageSize and @PageSize>5000) or @PageIndex<0 or @PageSize<0)
 --  return	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end

if(@PageIndex>@TotalPages)
  select @PageIndex=@TotalPages
select @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1          

declare @Group table(GroupID int primary key,GroupName nvarchar(100),
						Description nvarchar(100),Creator int,CreatedDate datetime,
						CurrencyID smallint,Currency varchar(5),QualifiedAmount money,NoAff int)

if DateDiff(m,CURRENT_TIMESTAMP,@Date) >= 0 -- current month
Begin
	insert into @Group(GroupID,GroupName,Description,Creator,CreatedDate,CurrencyID,Currency,QualifiedAmount)
	select GroupID,GroupName,Description,Creator,CreatedDate,CurrencyID,Currency,QualifiedAmount
	from (
			SELECT GroupID,GroupName,Description,CommGroup.Creator,CommGroup.CreatedDate,e.CurrencyID,e.CurrencyCode as Currency,QualifiedAmount		  
				,ROW_NUMBER() OVER(ORDER BY GroupID) AS TheCount
			from CommGroup with (nolock)
			inner join dbo.Currency e on CommGroup.Currency = e.CurrencyID
			where 			   
			GroupName like @GroupName and IsDeleted = 0 
			and (@Currencies = 'All' or (@Currencies is not null and CommGroup.Currency in (select val from @TblCurrency)))
		) x
	where x.TheCount between @RowStart and @RowEnd 
	
	Update t
	set t.NoAff=(select sum(1) from AffInfo i with (nolock) 
	where i.GroupID=t.GroupID 
			and (@IsITAdmin = 1 or i.TestLevel in (0,1)))
	from @Group t
End
else -- history
Begin
insert into @Group(GroupID,GroupName,Description,Creator,CreatedDate,CurrencyID,Currency,QualifiedAmount)
    select GroupID,GroupName,Description,Creator,CreatedDate,CurrencyID,Currency,QualifiedAmount
	 from (
			 SELECT GroupID,GroupName,Description,CommGroup.Creator,CommGroup.CreatedDate,e.CurrencyID,e.CurrencyCode as Currency,QualifiedAmount		  
				  ,ROW_NUMBER() OVER(ORDER BY GroupID) AS TheCount
			  from CommGroupHistory as CommGroup with (nolock)			       
			  inner join dbo.Currency e on CommGroup.Currency = e.CurrencyID
			   where GroupName like @GroupName and IsDeleted = 0 
			   and ( @Currencies = 'All' or (@Currencies is not null and CommGroup.Currency in (select val from @TblCurrency)))
			  and DateDiff(m,@Date,MonthDate) = 0
         ) x
     where x.TheCount between @RowStart and @RowEnd   
	
	Update t
	set t.NoAff=(
				select count(*) 
				from AffInfo ai WITH (NOLOCK)
					INNER JOIN	AffGroupHistory i with (nolock) on i.AffID = ai.AffID
				where i.GroupID=t.GroupID 
						and (@IsITAdmin = 1 or ai.TestLevel in (0,1))
						and datediff(m, MonthDate, @Date) = 0
				)
	from @Group t
End
 
select @GroupIDList = ''

select @GroupIDList = @GroupIDList + ',' + CONVERT(varchar, GroupID) from @Group	
 
select g.GroupID,g.GroupName,g.Description,isnull(i.username,'System') as Creator,g.CreatedDate,isnull(g.NoAff,0) as NoOfAffiliate,
		g.CurrencyID,g.Currency,g.QualifiedAmount		
from @Group g 
      left join AdminUser i with (nolock) on i.custid=g.Creator


GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSel] TO [vnteam]