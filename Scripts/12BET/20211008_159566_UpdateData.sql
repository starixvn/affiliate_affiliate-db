/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20211008@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Update Data

*/
DECLARE @WinlostDate DATETIME = '2021-09-01'

WHILE @WinlostDate <= '2021-10-09'
BEGIN
	EXEC [dbo].[Task_APIProduct_ImportQueue_Product]
	@ProductId		= 32,
	@WinlostDate	= @WinlostDate
	SET @WinlostDate = DATEADD(DAY, 1, @WinlostDate)
END

-- Update Commission
EXEC  [dbo].[Task_Aff_Monthly_Commission]  
		@MonthDate		= '2021-09-01',
		@IsForceUpdate	 =1

