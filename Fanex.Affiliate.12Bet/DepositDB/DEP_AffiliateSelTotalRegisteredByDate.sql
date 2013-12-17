Alter Procedure [DEP_AffiliateSelTotalRegisteredByDate]
	@AffId int,
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit
AS

-- DB: DEPOSIT.Deposit_DB
if @IsGetAll = 1
Begin
	SELECT datediff(d, 0, CreatDate) as ForeignKey,
		dateadd(d, 0, datediff(d, 0, CreatDate)) as CreatedDate,
		COUNT(CustId) as TotalRegistered
	FROM Deposit_Customer WITH(NOLOCK)
	WHERE AffiliateID = @AffId
	Group by datediff(d, 0, CreatDate), dateadd(d, 0, datediff(d, 0, CreatDate))
End
Else
Begin
	Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
	
	SELECT datediff(d, 0, CreatDate) as ForeignKey,
		dateadd(d, 0, datediff(d, 0, CreatDate)) as CreatedDate,
		COUNT(CustId) as TotalRegistered
	FROM Deposit_Customer WITH(NOLOCK)
	WHERE AffiliateID = @AffId
		and CreatDate between @FromDate and @ToDate
	Group by datediff(d, 0, CreatDate), dateadd(d, 0, datediff(d, 0, CreatDate))
End

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateSelTotalRegisteredByDate] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateSelTotalRegisteredByDate] TO [VNTeam]
GO