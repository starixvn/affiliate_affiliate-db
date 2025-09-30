/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_CommGroupSel]
	@GroupName nvarchar(100) = '',
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
	Task: Search a Commission Group (paging)
	DB: DBAFF12BET.Affiliate_12Bet
	Original:

	Revisions:
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]
		- 20180601@Percy: Flexible new setting [RemineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)
	
	if (isnull(@GroupName,'')='' OR lower(@GroupName)='[none]')
	begin
		select @TotalNoneGroup=count(1)
		from AffInfo a with (nolock)
			 inner join CommGroup c with (nolock) on c.GroupID=a.GroupID
		where c.GroupID>1000 and c.IsDeleted=0    
	end

	if(lower(@GroupName)='[none]')
	begin  
	   return
	end

	select @GroupName = '%' + @GroupName + '%'
	---CommGroup Detail va SportName se duoc cache tren web server dung co che notification
	DECLARE @RowStart int, @RowEnd int,@AffiliateID int

	select @Nrows=count(1)
	from CommGroup cg with (nolock)
	where GroupID between 101 and 1000 and GroupName like @GroupName and IsDeleted = 0 
		  and (
			  case when @FromDate is null or @ToDate is null then 1
					when CreatedDate between @FromDate and @ToDate then 1
					else 0
			  end     
		  )=1
		  AND EXISTS (SELECT 1 FROM dbo.GroupSetting g WITH (NOLOCK) WHERE cg.GroupId = g.GroupId)
	  
	 if(isnull(@NRows,0)=0 or (@NRows>@PageSize and @PageSize>5000) or @PageIndex<0 or @PageSize<0)
	   return	

	SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end
	if(@PageIndex>@TotalPages)
	  select @PageIndex=@TotalPages
	select @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1          

	declare @Group table(GroupID int primary key,GroupName nvarchar(100),Description nvarchar(100),Creator int,CreatedDate datetime,NoAff int)

	insert into @Group(GroupID,GroupName,Description,Creator,CreatedDate)
	 select GroupID,GroupName,Description,Creator,CreatedDate
		 from (
				 SELECT GroupID,GroupName,Description,Creator,CreatedDate		  
					  ,ROW_NUMBER() OVER(ORDER BY GroupID) AS TheCount
				  from CommGroup cg with (nolock)			       
				   where GroupID between 101 and 1000 and  GroupName like @GroupName and IsDeleted = 0 
				  and (
					  case when @FromDate is null or @ToDate is null then 1
							when CreatedDate between @FromDate and @ToDate then 1
							else 0
					  end     
					  )=1
				AND EXISTS (SELECT 1 FROM dbo.GroupSetting g WITH (NOLOCK) WHERE cg.GroupId = g.GroupId)
			 ) x
		 where x.TheCount between @RowStart and @RowEnd 
	Update t
	set t.NoAff=(select sum(1) from AffInfo i with (nolock) where i.GroupID=t.GroupID and i.status='Approved')
	from @Group t
 
	Select DTypeID, SportID, DTypeName, DTypeDesc, DeductedPercentage 
	from DeductionType (nolock)
	where IsTest <= @isTest
	
	Select DeductionID,GroupID,DeductedPercentage 
	from DeductionSetting (nolock)
	where GroupID in (select GroupID from @Group)	
 
	select g.GroupID,g.GroupName,g.Description,isnull(i.username,'System') as Creator,g.CreatedDate,isnull(g.NoAff,0) as NoOfAffiliate/*,(case when Exists(select top(1) 1 from AffCommission(nolock) where GroupID=g.GroupID) then 0 else 1 end) as IsAllowedToDelete	*/
	from @Group g 
		left join Affiliate_User i with (nolock) on i.custid=g.Creator

	select 
		g.GroupId,	
		g.SportType,
		s.SportName,
		g.TierID,
		g.MinAmount,
		g.MaxAmount,
		g.MinQM,
		g.MaxQM,
		g.Commission	
	from GroupSetting g with (nolock)
		 inner join SportType s with (nolock) on s.sportid=g.sporttype
	where g.GroupID in (
		 select GroupID from @Group
	   )
END
GO