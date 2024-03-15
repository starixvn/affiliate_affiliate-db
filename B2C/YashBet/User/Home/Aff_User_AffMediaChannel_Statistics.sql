/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffMediaChannel_Statistics]
	@AffId INT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery


	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/

BEGIN
	SET NOCOUNT ON

	SELECT c.ChannelCode, c.ChannelName, l.AffMediaLink, m.MarketName
	FROM dbo.AffMediaChannel c WITH (NOLOCK)
		INNER JOIN dbo.AffMediaLink l WITH (NOLOCK) ON c.AffId = l.AffId AND c.ChannelCode = l.ChannelCode
		INNER JOIN dbo.Market m WITH (NOLOCK) ON l.LanguageCode = m.MarketId
	WHERE c.AffId = @AffId AND l.IsShow = 1
	ORDER BY c.ChannelCode
END
GO