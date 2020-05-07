/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_AffiliateUser_ExtraUserInfoSel]
	@AffId INT
AS
/*
	Creator: 20180605@Walter
	Task:  Description - [Redmine: #87923]
	Database: DBAFFN88-Affiliate_N88

	Revisions:
		- 20180605@Walter : Get more info of aff user
*/
BEGIN
	SET NOCOUNT ON

    SELECT g.GroupName, 0 AS HasDailyDetail
    FROM CommGroup g WITH(NOLOCK)
		INNER JOIN AffInfo ai WITH(NOLOCK) ON g.GroupId = ai.GroupId
    WHERE ai.AffId = @AffId
END
GO