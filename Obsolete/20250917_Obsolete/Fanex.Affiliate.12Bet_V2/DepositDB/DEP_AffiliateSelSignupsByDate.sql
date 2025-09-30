--  exec DEP_AffiliateSelSummary @AffiliateID=927841,@MonthDate='Jan  1 2009 12:00:00:000AM',@NewSignUp=@p3 output,@TotalPlayer=@p4 output

ALTER PROCEDURE [dbo].[DEP_AffiliateSelSignupsByDate]
	@AffiliateID int,
	@FromDate smalldatetime,
	@ToDate smalldatetime,
	@NewSignUp int OUTPUT,
	@TotalDepositUsers int OUTPUT
AS
/*  
Created: 20120620@Johnny  
Task :   Get Signups member from deposit db
DB: DEPOSIT.Deposit_DB
Original: [DEP_AffiliateSelSignupsByDate] 
  
Revisions:  
- 
*/  

select @ToDate = dateadd(ms, -3, dateadd(d, datediff(d, 0, @ToDate) + 1, 0)) 
SELECT @NewSignUp = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)
WHERE AffiliateID = @AffiliateID 
	AND creatdate between @FromDate and @ToDate

SELECT @TotalDepositUsers = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)
WHERE AffiliateID = @AffiliateID 
	AND creatdate between @FromDate and @ToDate
	AND ActStatus in (2, 9)

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateSelSignupsByDate] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateSelSignupsByDate] TO [vnTeam]