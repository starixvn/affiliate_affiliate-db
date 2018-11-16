USE [Affiliate_12BET]
GO

/*
	Created: 20181109@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Insert new error messages
*/

INSERT INTO dbo.Messages(MessageId,MessageTypeId,Description,MessageContentEN)
SELECT 308, 2, 'Error! Change password unsuccessfully!', 'Error! Change password unsuccessfully!' UNION ALL
SELECT 401, 2, 'This affiliate has been added before.', 'This affiliate has been added before.' UNION ALL
SELECT 402, 2, 'Error! Add favorite unsuccessfully!', 'Error! Add favorite unsuccessfully!' UNION ALL
SELECT 403, 2, 'This affiliate has not been added before.', 'This affiliate has not been added before.' UNION ALL
SELECT 404, 2, 'Error! Delete favorite unsuccessfully!', 'Error! Delete favorite unsuccessfully!'

UPDATE dbo.Messages WITH (ROWLOCK, UPDLOCK)
SET
	MessageContentCS = MessageContentEN,
	MessageContentCH = MessageContentEN,
	MessageContentID = MessageContentEN,
	MessageContentVN = MessageContentEN,
	MessageContentTH = MessageContentEN,
	MessageContentKO = MessageContentEN,
	MessageContentES = MessageContentEN,
	MessageContentJP = MessageContentEN,
	MessageContentHIEN = MessageContentEN,
	MessageContentENEURO = MessageContentEN
WHERE MessageId IN (308,401,402,403,404)