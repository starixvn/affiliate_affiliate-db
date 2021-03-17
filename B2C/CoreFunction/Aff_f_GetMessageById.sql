/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetMessageById]
(
	@MessageId	INT,
	@Language	VARCHAR(10)
)
RETURNS NVARCHAR(2000)
AS

/*
	Creator: 20180601@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Function - Get message

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]

	Parameter's Explanation:
*/

BEGIN
	DECLARE @Message NVARCHAR(2000)

	SELECT @Message = CASE @Language
		WHEN 'en-US' THEN MessageContentEN
		WHEN 'zh-CN' THEN ISNULL(MessageContentCS, MessageContentEN)
		WHEN 'zh-TW' THEN ISNULL(MessageContentCH, MessageContentEN)
		WHEN 'id-ID' THEN ISNULL(MessageContentID, MessageContentEN)
		WHEN 'vi-VN' THEN ISNULL(MessageContentVN, MessageContentEN)
		WHEN 'th-TH' THEN ISNULL(MessageContentTH, MessageContentEN)
		WHEN 'ko-KR' THEN ISNULL(MessageContentKO, MessageContentEN)
		WHEN 'es-ES' THEN ISNULL(MessageContentES, MessageContentEN)
		WHEN 'ja-JP' THEN ISNULL(MessageContentJP, MessageContentEN)
		WHEN 'hi-IN' THEN ISNULL(MessageContentHIEN, MessageContentEN)
		WHEN 'eneuro' THEN ISNULL(MessageContentENEURO, MessageContentEN)
		ELSE MessageContentEN END
	FROM dbo.Messages WITH (NOLOCK)
	WHERE MessageId = @MessageId

	RETURN @Message
END
GO