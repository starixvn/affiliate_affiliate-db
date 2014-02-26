/*
	Task : 12Bet - EU migration: Cleanup EU & log data
	Author : Bobby.Nguyen@20140124
	DB: Affiliate_12Bet
*/

USE [Affiliate_12BET];
GO

--delete SeqAffInfo tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'SeqAffInfo'
			)
		) DROP TABLE [dbo].[SeqAffInfo];
GO

--delete AffInfo tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'EUAffiliates'
			)
		) DROP TABLE [dbo].[EUAffiliates];
GO

--delete MemberInfo tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'EUAffPlayers'
			)
		) DROP TABLE [dbo].[EUAffPlayers];
GO

--delete AffImport_Log tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'AffImport_Log'
			)
		) DROP TABLE [dbo].[AffImport_Log];
GO

--delete MemberImport_Log tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'MemberImport_Log'
			)
		) DROP TABLE [dbo].[MemberImport_Log];
GO
