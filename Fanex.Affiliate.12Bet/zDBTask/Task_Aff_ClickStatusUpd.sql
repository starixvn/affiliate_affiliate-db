ALTER PROCEDURE [dbo].[Task_Aff_ClickStatusUpd]
AS
/*
  Task to update status for click (just run earlier 6 hours)
  Writer : Johnny
  Date : 2012/01/11
  DB: DB052.Affiliate_12BET
  Revisions:    
		- 20120110@Johnny: Update click Status when member Signup
*/
SET NOCOUNT ON

Declare @CalculateTime smalldatetime--Subtract 6 hour

Select @CalculateTime = DATEADD(hh, -6, current_timestamp)

Update c
set c.[Status] = 1, c.UpdatedTime = t.CreatDate
From 
	ClickStatistics1 c 
	inner join 
		(Select AffiliateId, ClickId, CreatDate
		From 
			[DBDeposit].deposit_db.dbo.Deposit_Customer with (nolock)--For live code
			--deposit_db.dbo.Deposit_Customer with (nolock)--For local testing
		Where AffiliateId > 0 
			and ClickId > 0 
			and CreatDate >= @CalculateTime
		) t on c.ClickId = t.ClickId and c.AffId = t.AffiliateId
where c.[Status] = 0


GO
GRANT EXECUTE ON [dbo].[Task_Aff_ClickStatusUpd] TO [Dot_Member]
GO
GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClickStatusUpd] TO [vnteam]