USE [Affiliate_12BET]
GO

/*
	Created: 20180829@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new message for case duplicate player username [RedmineID: #87923]
*/

INSERT INTO dbo.Messages (MessageId, MessageTypeId, MessageContentEN)
	VALUES (3, 1, 'Player Username has been used. Please choose another one!')