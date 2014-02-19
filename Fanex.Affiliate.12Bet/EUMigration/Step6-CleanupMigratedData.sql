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

--delete AffInfo tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'EUAffiliates'
			)
		) DROP TABLE [dbo].[EUAffiliates];

--delete MemberInfo tmp
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'EUAffPlayers'
			)
		) DROP TABLE [dbo].[EUAffPlayers];


GO
