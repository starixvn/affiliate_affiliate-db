ALTER PROCEDURE [dbo].[AffAdmin_QualifiedMembersReport]
	@UserId int=0, 
	@AffId int,
	@MonthDate datetime
AS
/*    
Task : Qualified Members Report  
DB:    
Original: [AffAdmin_CommissionReport]
Revisions:           
                
Param's Explanation: 
• @UserId: Admin user id
• @AffId: Affiliate ID
• @Month: Month need to view
*/

SET NOCOUNT ON 

Declare @HasPermission bit

Select @HasPermission = [dbo].[AffAdmin_PermissionOnAffiliate](@UserId, @AffId)

IF(@HasPermission = 0)
	return

-- Get productid
Declare @FromDate datetime, @ToDate datetime, @QualifiedAmount money
		, @Sportsbook int, @NumberGame int, @LiveCasino int, @RNGCasino int

Select	@Sportsbook = dbo.[Aff_GetProductID]('Sportsbook')
		, @NumberGame = dbo.[Aff_GetProductID]('Number Game')
		, @LiveCasino = dbo.[Aff_GetProductID]('Live Casino')
		, @RNGCasino = dbo.[Aff_GetProductID]('RNG Casino')
		, @FromDate = dbo.Aff_GetFirstDayOfMonth(@MonthDate)
		, @ToDate = dbo.Aff_GetLastDayOfMonth(@MonthDate)

Select @QualifiedAmount = [dbo].[AffAdmin_QualifiedAmount](@AffId, @MonthDate)

SELECT	m.Username
		, e.Code as Currency
		, @QualifiedAmount as QualifiedAmount--Get from group setting
		, Sum(case WHEN ProductId = @Sportsbook THEN Turnover * SysExRate ELSE 0 END) as SportsbookTurnover
		, Sum(case WHEN ProductId = @NumberGame THEN Turnover * SysExRate ELSE 0 END) as NumberGameTurnover
		, Sum(case WHEN ProductId = @LiveCasino THEN Turnover * SysExRate ELSE 0 END) as LiveCasinoTurnover
		, Sum(case WHEN ProductId = @RNGCasino THEN Turnover * SysExRate ELSE 0 END) as RNGCasinoTurnover
From MemberDaily m with (nolock)	
	Inner JOIN Exchange e WITH (NOLOCK) on m.Currency = e.ExchangeID
Where AffId = @AffID
	And WinlostDate between @FromDate AND @ToDate
Group BY m.Username, e.Code


GO
GRANT EXECUTE ON [dbo].[AffAdmin_QualifiedMembersReport] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_QualifiedMembersReport] TO [vnteam] AS [dbo]