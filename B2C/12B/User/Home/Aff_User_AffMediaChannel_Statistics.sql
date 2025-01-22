/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaChannel_Statistics]
	@AffId INT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery


	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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