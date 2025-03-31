/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaLink_Sel]
	@AffId INT
	,@ChannelCode VARCHAR(50) = ''
    
AS

/*
	Created: 20250331@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery

	Revisions:
		- 20250331@Lewis: Initialize SP [RedmineID: #222364]

*/

BEGIN
	SET NOCOUNT ON
	
	SELECT a.ChannelCode,c.ChannelName,a.AffMediaLink,m.MarketName,a.IsShow
	FROM dbo.AffMediaLink a WITH (NOLOCK)
	INNER JOIN AffMediaChannel c WITH (NOLOCK) ON a.ChannelCode = c.ChannelCode AND a.AffId = c.AffId
	INNER JOIN Market m WITH (NOLOCK) ON a.LanguageCode = m.MarketId
	WHERE a.AffId = @AffId
		AND a.ChannelCode = @ChannelCode

END
GO

