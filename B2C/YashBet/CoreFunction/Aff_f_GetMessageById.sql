/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetMessageById]
(
	@MessageId	INT,
	@Language	VARCHAR(10)
)
RETURNS NVARCHAR(2000)
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Function - Get message

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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
		WHEN 'ms-MY' THEN ISNULL(MessageContentMS, MessageContentEN)
		WHEN 'km-KH' THEN ISNULL(MessageContentKH, MessageContentEN)
		WHEN 'bn-BD' THEN ISNULL(MessageContentBN, MessageContentEN)
		ELSE MessageContentEN END
	FROM dbo.Messages WITH (NOLOCK)
	WHERE MessageId = @MessageId

	RETURN @Message
END
GO