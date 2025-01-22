/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_GetMessageById]
(
	@MessageId	INT,
	@Language	VARCHAR(10)
)
RETURNS NVARCHAR(2000)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Function - Get message

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

	Parameter's Explanation:
*/

BEGIN
	DECLARE @Message NVARCHAR(2000)

	SELECT @Message = CASE @Language
		WHEN 'bn-BD' THEN ISNULL(MessageContentBN, MessageContentEN)
		WHEN 'en-GB' THEN ISNULL(MessageContentENEURO, MessageContentEN)
		WHEN 'en-US' THEN MessageContentEN
		WHEN 'hi-IN' THEN ISNULL(MessageContentHI, MessageContentEN)
		WHEN 'en-IN' THEN ISNULL(MessageContentHIEN, MessageContentEN)
		WHEN 'id-ID' THEN ISNULL(MessageContentID, MessageContentEN)
		WHEN 'ja-JP' THEN ISNULL(MessageContentJP, MessageContentEN)
		WHEN 'km-KH' THEN ISNULL(MessageContentKH, MessageContentEN)
		WHEN 'ko-KR' THEN ISNULL(MessageContentKO, MessageContentEN)
		WHEN 'te-IN' THEN ISNULL(MessageContentHITG, MessageContentEN)
		WHEN 'th-TH' THEN ISNULL(MessageContentTH, MessageContentEN)
		WHEN 'vi-VN' THEN ISNULL(MessageContentVN, MessageContentEN)
		WHEN 'zh-CN' THEN ISNULL(MessageContentCS, MessageContentEN)
		WHEN 'zh-TW' THEN ISNULL(MessageContentCH, MessageContentEN)
		ELSE MessageContentEN END
	FROM dbo.Messages WITH (NOLOCK)
	WHERE MessageId = @MessageId

	RETURN @Message
END
GO