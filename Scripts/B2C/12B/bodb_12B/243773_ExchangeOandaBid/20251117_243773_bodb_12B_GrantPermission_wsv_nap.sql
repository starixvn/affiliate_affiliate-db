/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20251117@Sophia
	DB: DB12B-bodb_12B
	Task: Grant permissions for wsv_nap to access bodb_12B and execute ExchangeDailyOanda_Bid stored procedures [RedmineID: #243773]
*/

USE [bodb_12B]
GO

-- Create user wsv_nap if not exists
IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'wsv_nap')
BEGIN
	CREATE USER [wsv_nap] FOR LOGIN [wsv_nap] WITH DEFAULT_SCHEMA=[dbo]
	PRINT 'User wsv_nap created successfully.'
END
 