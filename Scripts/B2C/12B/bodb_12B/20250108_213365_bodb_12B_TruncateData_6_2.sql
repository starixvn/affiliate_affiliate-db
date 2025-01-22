/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250108@Eddie
	DB: DB12B-bodb_12B
	Task: Truncate all tables [RedmineId : #212201]

*/
USE bodb_12B
GO

TRUNCATE TABLE [dbo].[API_PushDataTracker]
GO
TRUNCATE TABLE [dbo].[API_Queue]
GO
TRUNCATE TABLE [dbo].[API_TimeTracker]
GO
TRUNCATE TABLE [dbo].[BonusInfo]
GO
TRUNCATE TABLE [dbo].[Customer]
GO
TRUNCATE TABLE [dbo].[DepositInfo]
GO
TRUNCATE TABLE [dbo].[JobLog]
GO
TRUNCATE TABLE [dbo].[12B_SumWinloss]
GO
TRUNCATE TABLE [dbo].[RebateMLog]
GO
TRUNCATE TABLE [dbo].[SystemSettings]
GO
TRUNCATE TABLE [dbo].[TpBetRecord]
GO
TRUNCATE TABLE [dbo].[TpExchange]
GO
TRUNCATE TABLE [dbo].[TpGameType]
GO
TRUNCATE TABLE [dbo].[TpReport9W]
GO
TRUNCATE TABLE [dbo].[TpWager9W]
GO
TRUNCATE TABLE [dbo].[ServerInfo]
GO
TRUNCATE TABLE [dbo].[WithdrawalInfo]
GO