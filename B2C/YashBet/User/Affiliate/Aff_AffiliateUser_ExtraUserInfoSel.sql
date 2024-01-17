/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateUser_ExtraUserInfoSel]
	@AffId INT
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
*/
BEGIN
	SET NOCOUNT ON

    SELECT g.GroupName, 0 AS HasDailyDetail
    FROM CommGroup g WITH(NOLOCK)
		INNER JOIN AffInfo ai WITH(NOLOCK) ON g.GroupId = ai.GroupId
    WHERE ai.AffId = @AffId
END
GO