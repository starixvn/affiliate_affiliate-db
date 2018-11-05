USE [Affiliate_12BET]
GO

/*
	Created: 20181029@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Initialize data of ContactApps
*/

UPDATE dbo.AffDetail WITH (ROWLOCK, UPDLOCK)
SET ContactApps = N'[{"Name":"MSN/YM/QQ","Value":"' + ISNULL(CONVERT(NVARCHAR(200), MobilePhone), '') + N'","Order":0}]'
WHERE ContactApps IS NULL