set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER PROCEDURE [dbo].[Aff_ReportQM]
	@ProductID int=0,
	@AffName varchar(50) = NULL,
	@AffType tinyint = 0,
	@PreferredLanguage varchar(11) = null,
	@Currency smallint = 0,
	@Month int,
	@Year int,
	@PageSize int=50,    
	@PageIndex int=1,    
	@TotalPages int=0 OUTPUT,    
	@NRows int=0 OUTPUT    
AS

/*
Created: 20091213@Peter
Task : Get Qualifying member report for all affiliates.
DB: DB052.Affiliate_ZZun
Original: 
Revisions:
    
Param's Explanation:
	
*/
SET NOCOUNT ON

select @AffName= '%' + Coalesce(@AffName, '') + '%'

Declare @FirstDay smalldatetime,@LastDay smalldatetime, @MaxWinlostDate smalldatetime
        


Select @FirstDay = cast(cast(@Year as varchar(5)) + '-' + cast(@Month as varchar(5)) + '-' +'1' as smalldatetime)
 --Get last day of inputted month
Select @LastDay = dbo.Aff_GetLastDayOfMonth(@FirstDay)
     
  
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),QualifiedAmount float,AffTypeName varchar(50))
create table #report(TheCount int IDENTITY(1,1), AffId int ,Product varchar(50), UserName varchar(30), QualifiedMember int,AffTypeName varchar(50))
insert into @TempAff
select ai.AffID, ai.UserName,co.QualifiedAmount,at.Name as AffTypeName
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
		inner join CommGroup co with(nolock) on ai.GroupId = co.GroupId
		left join AffType at with (nolock) on ai.AffType = at.TypeID
	WHERE ai.Status='Approved'	
	and (@AffType = 0 or ai.AffType = @AffType)
	and ai.Username like @AffName
	and (@PreferredLanguage is null or @PreferredLanguage=ad.PreferredLanguage)
	and (@Currency=0 or  @Currency= ai.Currency	)
	and ai.ApprovedDate<=@LastDay


select @MaxWinlostDate=max(WinlostDate) from AffCommission with (nolock)



if(@MaxWinlostDate is not null and @LastDay<=@MaxWinlostDate) --Get Data from AffCommission
BEGIN

 insert into #report(AffId ,Product, UserName, QualifiedMember,AffTypeName)
 select ac.AffID, a.UserName,p.ProductName as Product,ac.QualifiedMember,a.AffTypeName
			from AffCommission ac with (nolock)    
				inner join @TempAff a  on ac.AffID=a.AffID                
                inner join Product p with (nolock) on p.ProductID=ac.ProductID
			where ac.WinlostDate = dbo.Date_Only(@LastDay)   
				 and (@ProductID=0 or ac.ProductID=@ProductID)
				 and ac.MemberTurnover>0      
	order by ac.QualifiedMember desc,ac.AffID ,p.ProductName		 
select @NRows=@@ROWCOUNT
		 
END
else --Calculate data for uncalculated month
BEGIN
	  	
    Declare  @CurrDate smalldatetime
        
    select @CurrDate =  convert(varchar(10),current_timestamp,120),
		@LastDay = (case when @LastDay >= @CurrDate then @CurrDate else @LastDay end)

 insert into #report(AffId ,Product, UserName, QualifiedMember,AffTypeName)
  Select a1.AffID,t.Product as Product, t.AffName as UserName,
	sum(case when t.TurnOver>=a1.QualifiedAmount then 1 else 0 end) as QualifiedMember,
	a1.AffTypeName
	  from  @TempAff a1
	 inner join
	 ( 
	   select a.AffID,a.userName as AffName,m.USerName,p.ProductName as product,sum(TurnOver * AffExRate) as TurnOver
	   from MemberDaily m (nolock)
			inner join @TempAff a on a.AffID=m.AffID   
			inner join Product p with (nolock) on p.ProductID=m.productID    
		where m.Winlostdate between  @FirstDay and @LastDay and m.Turnover>0
		   and (@ProductID=0 or m.ProductID=@ProductID)
	   group by a.AffID,a.userName,m.USerName,p.ProductName

	 ) t on a1.AffID=t.AffID

	 group by  a1.AffID,t.AffName, t.Product,a1.AffTypeName
	 order by sum(case when t.TurnOver>=a1.QualifiedAmount then 1 else 0 end) desc,a1.AffID, t.Product		 

    select @NRows=@@ROWCOUNT 
 	
END


if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   

select * from #report (nolock)

where TheCount between @RowStart and @RowEnd

drop table #report

GO

GO
GRANT EXECUTE ON [dbo].[Aff_ReportQM] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ReportQM] TO [VNTeam] 

