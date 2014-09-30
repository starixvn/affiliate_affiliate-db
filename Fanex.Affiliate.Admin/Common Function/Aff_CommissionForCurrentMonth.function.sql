ALTER FUNCTION [dbo].[Aff_CommissionForCurrentMonth] (@AffID INT)
RETURNS @AffComm TABLE (
	ProductID INT
	,TotalQM INT
	,commission DECIMAL(9, 8)
	,amount MONEY
	,MemDeposit MONEY
	,MemTurnOver MONEY
	,MemWinlost MONEY
	,NetWinlost MONEY
	)
AS
/*
Task : Calculate monthy earning for affiliate
Author : Peter@20090909

Revisions:
	- 20120514@Peter : Apply new formula according to Joycee's request
		 IF Winloss in SPORTSBOOK > winloss in Casino then 
			   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee - PSP Fe
				Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee
		 else
			   CNW in sportspook=Member Winlost In SB - Marketing Fee- Odds Fee
			   Net Winlost for Casino = Member Winlost In Casino - Marketing Casino - Playtech Royalty Fee - PSP Fee
	- 20140425@Bobby: fixing NoCommision group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
	- 20140909@Bobby.Nguyen: Apply  Sharing fee - PlayerComm (Re-structure)
*/
BEGIN
	DECLARE @Month 	INT
		,@Year 		INT
		
	SELECT @Month	= MONTH(CURRENT_TIMESTAMP)
		, @Year		= YEAR(CURRENT_TIMESTAMP)
		
	INSERT INTO @AffComm (
		ProductID
		,TotalQM
		,commission
		,amount
		,MemDeposit
		,MemTurnOver
		,MemWinlost
		,NetWinlost
		)
	SELECT ProductID
		,TotalQM
		,commission
		,amount
		,MemDeposit
		,MemTurnOver
		,MemWinlost
		,NetWinlost
	FROM [dbo].[Aff_CommissionForMonth](@AffID, @Month, @Year)

	RETURN;

END
