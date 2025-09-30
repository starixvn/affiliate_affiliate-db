ALTER PROCEDURE [dbo].[AffAdmin_CalMonthlyEarning] (
	@AffID 				INT
	,@Month 			INT
	,@Year 				INT
	,@ProductID 		INT = 0
	,@Amount 			MONEY OUTPUT
	)
AS
/*  Task : Calculate monthy earning for affiliate
    Author : Peter@20090909
    -20100709@Peter:
                    http://ccs.sunplus.vn/viewtopic.php?f=4&t=2890&st=0&sk=t&sd=a&start=10
                    Change the way to calculation:

                    if CNW <0 then we must also use the condition of Qualifying Members ( old way does not have)
                     and the minimum commission in this case is 10%  if the qualifying members <5. 
    -20100927@Peter:
                 http://ccs.sunplus.vn/viewtopic.php?f=4&t=3845&p=19236#p19236  
                 Change the way to calculation:
                   PSP=deposit * depositpercent + withdrawal * withdrawalpercent
                      For European Currencies: EURO,AUD,GBP, US$
                          + depositpercent=0.06
                          + withdrawalpercent=0.03
                      For Asian Currencies:
                          + depositpercent=0.02
                          + withdrawalpercent=0.02
                   PSP now follow tier commission
                   New Fee:  Odds Management Fee = 17 % MemberWinlost
                   CNW= MemberWinlost - Odds Management Fee - Marketing Fee - PSP Fee
                   From CNW => AComm
                   Affiliate Earning=(CNW - Bonus - Adjustement)* AComm

	- 20140418@Bobby: Check NoCommission group
	- 20140702@Bobby.Nguyen: Force to update Commission  when Company Net Win is negative
	- 20140909@Bobby.Nguyen: Re-structure SP
*/
BEGIN
	SET NOCOUNT ON
	
	DECLARE @CommAmount		MONEY

	EXEC [dbo].[Aff_CalMonthlyEarning]
		@AffID			= @AffID
		,@Month			= @Month
		,@Year			= @Year
		,@ProductID 	= @ProductID
		,@Amount  		= @CommAmount OUTPUT
	
	SET @Amount = ISNULL(@CommAmount, 0);
	RETURN;
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CalMonthlyEarning] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CalMonthlyEarning] TO [vnteam]
GO
