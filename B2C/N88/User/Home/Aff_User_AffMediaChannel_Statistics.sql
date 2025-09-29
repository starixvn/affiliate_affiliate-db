/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_AffMediaChannel_Statistics]
	@AffId INT
AS

/*
	Created: 20201215@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20201215@Percy: Initialize SP [RedmineID: #146201]
		- 20250729@Danny: handle IsDelete column (market table) [RedmineID: #227560]
*/

BEGIN
	SET NOCOUNT ON

	SELECT c.ChannelCode, c.ChannelName, l.AffMediaLink, m.MarketName
	FROM dbo.AffMediaChannel c WITH (NOLOCK)
		INNER JOIN dbo.AffMediaLink l WITH (NOLOCK) ON c.AffId = l.AffId AND c.ChannelCode = l.ChannelCode
		INNER JOIN dbo.Market m WITH (NOLOCK) ON l.LanguageCode = m.MarketId
	WHERE c.AffId = @AffId AND l.IsShow = 1 AND m.IsDeleted = 0
	ORDER BY c.ChannelCode
END
GO