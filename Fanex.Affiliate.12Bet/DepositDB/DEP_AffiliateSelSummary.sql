--  exec DEP_AffiliateSelSummary @AffiliateID=927841,@MonthDate='Jan  1 2009 12:00:00:000AM',@NewSignUp=@p3 output,@TotalPlayer=@p4 output

ALTER PROCEDURE [dbo].[DEP_AffiliateSelSummary]
	@AffiliateID int,
	@MonthDate smalldatetime, --first day of the month
	@NewSignUp int OUTPUT,	-- input_month only
	--@NewSignUpDep int = 0 OUTPUT,	
	@TotalPlayer int OUTPUT -- up to Now
	--@TotalPlayerDep int = 0 OUTPUT -- up to Now	
AS
-- DB: DEPOSIT.Deposit_DB

SELECT @NewSignUp = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)
WHERE AffiliateID = @AffiliateID 
	AND DATEDIFF(MONTH,@MonthDate,creatdate) = 0
	
/*SELECT @NewSignUpDep = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)
WHERE AffiliateID = @AffiliateID 
	AND ActStatus in (2, 9)
	AND DATEDIFF(MONTH,@MonthDate,creatdate) = 0*/

SELECT @TotalPlayer = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)	
WHERE AffiliateID = @AffiliateID 
	
/*SELECT @TotalPlayerDep = COUNT(*)
FROM Deposit_Customer WITH(NOLOCK)	
WHERE AffiliateID = @AffiliateID 
	AND ActStatus in (2, 9)
*/		
GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateSelSummary] TO [bodbAffiliateNet]