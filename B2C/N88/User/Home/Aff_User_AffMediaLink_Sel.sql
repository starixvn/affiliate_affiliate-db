/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_AffMediaLink_Sel]
	@AffId INT
	,@ChannelCode VARCHAR(50) = ''
    
AS
/*
	Created: 20250804@Lewis
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: User site - Home - Account Overview - Affiliate Link / Media Gallery
	
	Revisions:
		- 20250804@Lewis: Initialize SP [RedmineID: #227560]
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