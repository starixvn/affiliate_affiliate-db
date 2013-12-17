USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateCommReport]    Script Date: 12/23/2010 13:05:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
 ALTER Procedure [dbo].[Aff_AffiliateCommReport]
	@MonthDate datetime=null,		
	@SportId tinyint=null,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_12BET
Original: [Aff_AffiliateCommReport]
Revisions:
	-20120508@Johnny: Add dropdown box for sport type
Param's Explanation:
	• @Fromdate Time search From
	• @Todate Time search To,
	• @IsGetAll if getall = 1 => get data in all date,
	• @UserName Affiliate username need to search(must match username),
	• @PageSize Page Size,
	• @PageIndex Current page,
	• @TotalPages num pages return,
	• @NRows num rows return
*/
Set Nocount On

declare @Todate datetime
select @UserName= '%' + Coalesce(@UserName, '') + '%'

select @MonthDate=convert(varchar(10),DATEADD(s,-1,DATEADD(mm, DATEDIFF(m,0,@MonthDate)+1,0)),120),
	   @ToDate = dateadd(d, -1, dateadd(m, datediff(m, 0, @MonthDate) + 1, 0))--Assign todate to last date of month of todate

declare @SportbookId int, @CasinoId int

select @SportbookId=dbo.Aff_GetSportID('SportsBook'), @CasinoId=dbo.Aff_GetSportID('Casino')

 declare @month int, @year int
select @month=MONTH(@MonthDate),@year= YEAR(@MonthDate)

--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE ai.Status='Approved'
	--and ai.IsClosed=0
	and ai.Username like @UserName
	and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
	and AffType = @AffType
	and ai.ApprovedDate < @ToDate  

if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int,@AffectedRows int     
	
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
	   @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
		
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),IsClosed bit,Commission decimal(9,8), AffComm money)

insert into @TempAff
select m.AffId, m.username,m.IsClosed,0,0
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.IsClosed,ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage,ai.IsClosed
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
	where ai.Status = 'Approved'
		--and ai.IsClosed=0
		and ai.Username like @UserName  
		and isnull(@PreferredLanguage, ad.PreferredLanguage) = ad.PreferredLanguage
		and AffType = @AffType	
		and ai.ApprovedDate < @ToDate  
	)m 
where m.TheCount between @RowStart and @RowEnd      
select @AffectedRows=@@ROWCOUNT

if(not exists (select top(1) 1 from AffCommission(nolock) where winlostdate=@MonthDate))			
begin	
		
		if(datediff(m,current_timestamp,@MonthDate)=0)
		begin
			--calculate for current month and display the data

			update t
			set t.Commission=coalesce(a.commission,0),
			   t.AffComm=coalesce(a.Amount,0)
			from   @TempAff as t 
			  CROSS APPLY [dbo].[Aff_CommissionForCurrentMonth](t.AffID) as a
			where ISNULL(@SportId, a.SportID)=a.SportID
		
		end
		else
		begin
		  
			
			update t
			set t.Commission=coalesce(a.commission,0),
			   t.AffComm=coalesce(a.Amount,0)
			from   @TempAff as t 
			  CROSS APPLY [dbo].[Aff_CommissionForMonth](t.AffID,@Month,@Year) as a
			where  ISNULL(@SportId, a.SportID)=a.SportID

		
		end	
		--Select the result Data in order
		Select t.AffId,
			t.Username,
			t.IsClosed,
			Commission,
			t.AffComm
			From @TempAff as t
			order by t.IsClosed,t.AffId, t.Username
	end
else
	begin
			Select t.AffId,
			t.Username,
			t.IsClosed,
			isnull(t2.Commission, 0) as Commission,
			isnull(t2.AffWinlost, 0) as AffComm		
			From @TempAff t left join
			(		
				Select ac.AffId,
					ac.Commission,
					ac.AffWinlost
				From AffCommission ac with(nolock)						
					inner join @TempAff t1 on t1.AffId=ac.AffId			
				where winlostdate=@MonthDate
						and SportId=@SportId
			) t2 on t.AffId = t2.AffId
			order by t.IsClosed,t.AffId, t.Username	
	end

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCommReport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCommReport] TO [VNTeam] 