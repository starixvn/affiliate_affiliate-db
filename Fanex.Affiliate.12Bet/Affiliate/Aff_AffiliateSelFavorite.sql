Alter Procedure [Aff_AffiliateSelFavorite]  
	@UserId int=-1,
	@GroupID int=-1,
	@GroupName nvarchar(100)=NULL Output,
	@Status varchar(30),  
	@AffID int=-1,
	@UserName nvarchar(50)=NULL,  
	@Email nvarchar(50)=NULL,  
	@AffType tinyint = 0,
	@PageSize int=50,  
	@PageIndex int=1,  
	@TotalPages int=0 OUTPUT,  
	@NRows int=0 OUTPUT  
AS    
/*
Task : Get All Favorite Affiliate for a specific page  
DB: DB052.Affiliate_12BET
Original:[Aff_CustomerSelAffiliate]  
Revisions:      
 - 20100208@Johnny: show one more column PreferredLanguage
				
Param's Explanation:  
. @GroupID : if @GroupID<>-1 : only search by GroupID and this function is linked from Commission Group Page
. @GroupName : Search by GroupName
• @Status : pending,Approved,disapproved  
• @UserName : Affiliate name you want to default value=null :search all  
• @Email : Email you want to search - default value=null :search all  
• @PageSize : Number of rows should be returned per each page  
• @PageIndex : Current page   
• @TotalPages OUTPUT : total of pages for this search  
  
• @NRows OUTPUT,--total of rows  
  
*/  
SET NOCOUNT ON
select @UserName= '%' + Coalesce(@UserName, '') + '%'     
select @Email= '%' + Coalesce(@Email, '') + '%'     

declare @GroupIDList table(GroupID int)

if(isnull(@GroupName,'')<>'' )
 begin   
	if(lower(@GroupName)='[none]')
	begin
		insert into @GroupIDList(GroupID)    
		select GroupID 
		from CommGroup (nolock)
		where GroupID>1000
	end
	else
	begin
		declare @grName nvarchar(100)
		select @grName= '%' + Coalesce(@GroupName, '') + '%'   
		insert into @GroupIDList(GroupID)    
		select GroupID 
		from CommGroup (nolock)
		where GroupName like @grName
	end
	if(@@ROWCOUNT=0)
	begin
	   return	
	end   
 end
  
  
--count nrows    
select @NRows=count(1)    
FROM     
	AffInfo ai with (nolock)  
	inner join AdminFavorite f with (nolock) on ai.AffId = f.AffId 
WHERE f.AdminId = @UserId  
	and (case when @AffID = -1 then 1   
				  when ai.AffId=@AffID then 1  
				  else 0  
			  end) =1   
	and Status = @Status
	and Username like @UserName
	and Email like @Email
	and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1
			  when @GroupID =0 and GroupID>1000 then 1
			  when @GroupID=-1 and  isnull(@GroupName,'')='' then 1
			  when exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1
			  else 0
		  end 
		)=1	
	and (@AffType is null or AffType = @AffType)
	
if(isnull(@NRows,0)=0)    
   return    
	   
DECLARE @RowStart int, @RowEnd int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
 
 
DECLARE @TempMember TABLE(AffId int PRIMARY KEY, UserName nvarchar(30), FirstName nvarchar(50), LastName nvarchar(50), PreferredLanguage varchar(11), IsClosed bit, ApprovedDate smalldatetime, GroupId int, CasinoJoinedDate smalldatetime)

insert into @TempMember(AffId, UserName, FirstName, LastName, PreferredLanguage, IsClosed, ApprovedDate, GroupId, CasinoJoinedDate)  
select m.AffId, m.username, m.firstname, m.lastname, m.PreferredLanguage, m.IsClosed, m.ApprovedDate, m.GroupId, m.CasinoJoinedDate 
from
	(select ROW_NUMBER() OVER(ORDER BY IsClosed, ai.Username) AS TheCount,
		ai.AffID, ai.UserName, ai.FirstName, ai.LastName, ad.PreferredLanguage, ai.IsClosed, ai.ApprovedDate, ai.GroupId, ai.CasinoJoinedDate 
	from AffInfo ai with (nolock)		
		inner join AffDetail ad with(nolock) on ai.AffId = ad.AffId
		inner join AdminFavorite f with (nolock) on ai.AffId = f.AffId   
	where f.AdminId = @UserId
		and (case when @AffID = -1 then 1   
				  when ai.AffId=@AffID then 1  
				  else 0  
			  end) =1   
	and Status = @Status
	and ai.Username like @UserName
	and ai.Email like @Email
	and (case when @GroupID > 0 and GroupID<1000 and GroupID=@GroupID then 1
			  when @GroupID =0 and GroupID>1000 then 1
			  when @GroupID=-1 and  isnull(@GroupName,'')='' then 1
			  when exists(select 1 from @GroupIDList) and GroupID in (Select GroupID from @GroupIDList) then 1
			  else 0
		  end 
		)=1	
	and (@AffType is null or AffType = @AffType)
	)m
where m.TheCount between @RowStart and @RowEnd 
		
if(@GroupID>0)
begin
  select @GroupName=GroupName
  from CommGroup with (nolock)
  where @GroupID=GroupID
end

if(@GroupID=0)
  select @GroupName='[None]'
  
select x.AffId, x.username, x.firstname, x.lastname, x.PreferredLanguage, x.IsClosed, isnull(cg.GroupName, '[None]') as GroupName,   
	isnull(dbo.Aff_CountMember(x.AffID),0) as NoOfMember, isnull(dbo.Aff_GetAffBalance(x.AffID),0) as BalanceBF, ApprovedDate, isnull(x.Affid, 0) as Favorite,x.GroupId  
	, x.CasinoJoinedDate
from @TempMember x  	
	left join CommGroup cg with (nolock) on x.GroupId = cg.GroupId  
ORDER BY IsClosed, Username  
	
  
GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelFavorite] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelFavorite] TO [vnteam]