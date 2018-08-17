/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_GetMessageById]
(
	@MessageId	INT,
	@Language	VARCHAR(10)
)
RETURNS NVARCHAR(2000)
AS

/*
	Creator: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Function - Get message

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]

	Parameter's Explanation:
*/

BEGIN
	DECLARE @Message NVARCHAR(2000)

	SELECT @Message = CASE @Language
		WHEN 'en-US' THEN MessageContentEN
		WHEN 'zh-CN' THEN MessageContentCS
		WHEN 'zh-TW' THEN MessageContentCH
		WHEN 'id-ID' THEN MessageContentID
		WHEN 'vi-VN' THEN MessageContentVN
		WHEN 'th-TH' THEN MessageContentTH
		WHEN 'ko-KR' THEN MessageContentKO
		WHEN 'es-ES' THEN MessageContentES
		WHEN 'ja-JP' THEN MessageContentJP
		WHEN 'hi-IN' THEN MessageContentHIEN
		WHEN 'eneuro' THEN MessageContentENEURO
		ELSE MessageContentEN END
	FROM dbo.Messages WITH (NOLOCK)
	WHERE MessageId = @MessageId

	RETURN @Message
END
GO