set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER Procedure [dbo].[Aff_PlayersSelDetail]
	@AffID int,
	@ProductID tinyint = 0,
	@MonthDate datetime = null,
	@PageSize int=200,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS
/*
	Created: @VietHoang
	Task : 
	DB: DB052.Affiliate_MYM	
	Revisions:		
	    - 20100511@Johnny: upgrade performance(paging first and then calculate member related)
	Param's Explanation:
		• @AffID : Affiliate custid
		• @MonthDate: Month search. If Month is null => get all month Else get just the specification month		
		----Continue....
*/
SET NOCOUNT ON
DECLARE  @Today datetime,@fdate datetime, @tdate datetime
SELECT @Today = convert(varchar(10),current_timestamp,120)



IF @MonthDate is not NULL
BEGIN
	SELECT @fdate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
	select @tdate = dbo.Aff_GetLastDayOfMonth(@MonthDate)
END


Create table #ListCustId(TheCount int IDENTITY(1,1),username varchar(100),TurnOver money,winlost money,deposit money,withdrawal money,bonus money,adjustment money,psp money,AffCurrency varchar(8),Description varchar(100))

insert into #ListCustId(username,TurnOver,winlost,deposit,withdrawal,bonus,adjustment,psp,AffCurrency,Description)


select  m.username, 
		isnull(sum(d.turnover * d.AffExRate), 0) as turnover, 
		isnull(sum(d.winlost * d.AffExRate), 0) as winlost,
		isnull(sum(d.deposit  * d.AffExRate), 0) as deposit,
		isnull(sum(d.withdrawal  * d.AffExRate), 0) as withdrawal,
		isnull(sum(d.bonus * d.AffExRate), 0) as bonus, 
		isnull(sum(d.Adjustment * d.AffExRate), 0) as Adjustment,
		isnull(sum(d.PSP  * d.AffExRate), 0) as PSP,
		e.Code as AffCurrency,
        (case when m.IsRemoved=1 then 'Member is removed since ' + 
                                 (select cast(RemovedDate as varchar(50))
                                   from MemberRemoval (nolock) where username=m.username)
        else '' end) as Description
	from MemberDaily d with (nolock)
		inner join MemberInfo m with(nolock) on m.username = d.username
		left join Exchange e on e.ExchangeID = d.AffCurrency
	where m.AffID=@AffID 
	and (@ProductID=0 or d.ProductID= @ProductID)
	and d.AffID = @AffID
	and (turnover > 0 or deposit > 0 or withdrawal>0 or bonus>0 or Adjustment>0 or PSP>0 )
    and (@MonthDate is NULL or d.winlostdate between @fdate and @tdate)    
	group by m.username,e.Code,m.IsRemoved
order by Username	

select @NRows=@@ROWCOUNT


DECLARE @RowStart int, @RowEnd int	

SELECT @TotalPages=@NRows/@PageSize + case when @NRows%@PageSize>0 then 1 else 0 end,
       @PageIndex = @PageIndex - 1, @RowStart = @PageSize * @PageIndex + 1, @RowEnd = @RowStart + @PageSize - 1   


select * from #ListCustId (nolock) where TheCount between @RowStart and @RowEnd

drop table #ListCustId



GO
GRANT EXECUTE ON [dbo].[Aff_PlayersSelDetail] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayersSelDetail] TO [VNTeam]