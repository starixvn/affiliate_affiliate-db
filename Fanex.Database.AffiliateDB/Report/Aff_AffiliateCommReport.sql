set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go
 ALTER Procedure [dbo].[Aff_AffiliateCommReport]
	@MonthDate datetime=null,		
	@ProductID tinyint=0,
	@UserName nvarchar(50)=NULL,
	@PreferredLanguage varchar(11) = null,
	@Currency varchar(5) = 0,
	@AffType tinyint = 0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
Created: @Peter
Task : Get report of Active members 
DB: DB052.Affiliate_ZZun
Original: [Aff_AffiliateCommReport]
Revisions:
    
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

select @UserName= '%' + Coalesce(@UserName, '') + '%'

select @MonthDate=dbo.Date_Only([dbo].[Aff_GetLastDayOfMonth] (@MonthDate))



--count nrows
select @NRows=count(1)    
FROM  AffInfo ai with (nolock)  
	inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
WHERE ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage) 
	and (@Currency=0 or @Currency= ai.Currency) 
	and (@AffType=0 or AffType = @AffType)
	and ai.ApprovedDate <=  [dbo].[Aff_GetLastDayOfMonth] (@MonthDate)


if(isnull(@NRows,0)=0)    
	return  

DECLARE @RowStart int, @RowEnd int,@AffectedRows int     
    
SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,    
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1       
        
DECLARE @TempAff TABLE(AffId int PRIMARY KEY, UserName nvarchar(30),IsClosed bit, 
Currency varchar(5), AffComm money,AffTypeName varchar(50))

insert into @TempAff
select m.AffId, m.username,m.IsClosed, m.Currency,NULL,m.AffTypeName
from  
	(select ROW_NUMBER() OVER(ORDER BY ai.IsClosed,ai.AffId) AS TheCount,  
		ai.AffID, ai.UserName, ad.PreferredLanguage,ai.IsClosed, c.CurrencyCode as Currency,
		at.Name as AffTypeName
	from AffInfo ai with (nolock)    
		inner join AffDetail ad with (nolock) on ai.AffId = ad.AffId
       inner join Currency c with (nolock) on c.CurrencyID=ai.Currency
       left join AffType at with(nolock) on ai.AffType = at.TypeID
	WHERE ai.Status='Approved'	
	and ai.Username like @UserName
	and (@PreferredLanguage is null or @PreferredLanguage= ad.PreferredLanguage) 
	and (@Currency=0 or @Currency= ai.Currency) 
	and (@AffType=0 or AffType = @AffType)
	and ai.ApprovedDate <= [dbo].[Aff_GetLastDayOfMonth] (@MonthDate)
	)m 
where m.TheCount between @RowStart and @RowEnd      
select @AffectedRows=@@ROWCOUNT


if(not exists (select top(1) 1 from AffCommission(nolock) where winlostdate=@MonthDate))			
begin
		declare @AffID int,
		@Amount money, -- Amount with Marketing Fee included
		@Month int,
		@Year int,
		@count int
		
		if(datediff(m,current_timestamp,@MonthDate)=0)
		begin
			--calculate for current month and display the data
			select top(1) @AffId=AffID
			from @TempAff
			where AffComm is null	
			select @count=0
			--print @AffID		
			while(@AffId is not null and @count<@AffectedRows)
			begin
				exec [dbo].[Aff_CalMonthlyEarningCurrent] @AffID=@AffID,@ProductID=@ProductID, @Amount=@Amount OUTPUT
				update @TempAff
				set AffComm=isnull(@Amount,0)
				where AffID=@AffID
				--Get next AffID
				
				select top(1) @AffId=AffID
				from @TempAff
				where AffComm is null	
				
				set @count=@count+1
				
			end			
		end
		else
		begin
			--calculate for the month and display the data
			select @Month=month(@MonthDate),@Year=year(@MonthDate)
			select top(1) @AffId=AffID 
			from @TempAff
			where AffComm is null	
			select @count=0
					
			while(@AffId is not null and @count<@AffectedRows)
			begin
				exec [dbo].[Aff_CalMonthlyEarning] @AffID=@AffID,@Month=@Month,@Year=@Year,@ProductID=@ProductID,@Amount=@Amount OUTPUT
				update @TempAff
				set AffComm=isnull(@Amount,0)
				where AffID=@AffID
				--Get next AffID
				select top(1) @AffId=AffID 
				from @TempAff
				where AffComm is null	
				 set @count=@count+1					
			end
		end	
		--Select the result Data in order
		Select t.AffId,
			t.Username,
			t.IsClosed,
			t.Currency,
			t.AffComm,
			t.AffTypeName		
			From @TempAff t
			order by t.IsClosed,t.AffId, t.Username
	end
else
	begin
			Select t.AffId,
			t.Username,
			t.IsClosed,
			t.Currency,
			sum(t2.AffWinlost) as AffComm,
			t.AffTypeName		
			From @TempAff t left join
			(		
				Select ac.AffId,
					ac.AffWinlost
				From AffCommission ac with(nolock)						
					inner join @TempAff t1 on t1.AffId=ac.AffId			
				where winlostdate=@MonthDate
						and (@ProductID=0 or ProductID=@ProductID)
			) t2 on t.AffId = t2.AffId
            group by  t.AffId,
			t.Username,
			t.IsClosed,
			t.Currency,
			t.AffTypeName
			order by t.IsClosed,t.AffId, t.Username	
	end





GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateCommReport] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateCommReport] TO [VNTeam] 