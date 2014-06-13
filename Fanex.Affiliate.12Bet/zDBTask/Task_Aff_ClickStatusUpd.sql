ALTER PROCEDURE [dbo].[Task_Aff_ClickStatusUpd]
AS
/*
  Task to update status for click (just run earlier 6 hours)
  Writer : Johnny
  Date : 2012/01/11
  DB: DB052.Affiliate_12BET
  Revisions:    
	- 20120110@Johnny: Update click Status when member Signup
	- 20140613@Bobby: Update @CalculateTime to 7 days (cookie expiry)
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @CalculateTime SMALLDATETIME --Subtract 7 days

	SELECT @CalculateTime = DATEADD(DD, - 7, CURRENT_TIMESTAMP)

	UPDATE c
	SET c.[Status] = 1
		,c.UpdatedTime = t.CreatDate
	FROM ClickStatistics1 c
		INNER JOIN (
		SELECT AffiliateId
			,ClickId
			,CreatDate
		FROM [DBDeposit].deposit_db.dbo.Deposit_Customer WITH (NOLOCK) --For live code
		WHERE AffiliateId > 0
			AND ClickId > 0
			AND CreatDate >= @CalculateTime
		) t
		ON c.ClickId = t.ClickId
			AND c.AffId = t.AffiliateId
	WHERE c.[Status] = 0
END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_ClickStatusUpd] TO [Dot_Member]
GO

GRANT VIEW DEFINITION ON [dbo].[Task_Aff_ClickStatusUpd] TO [vnteam]
