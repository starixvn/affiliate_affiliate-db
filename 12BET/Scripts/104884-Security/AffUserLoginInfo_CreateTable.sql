USE [Affiliate_12BET]
GO

/*
	/*
	Created: 20190522@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: User Login - New table
*/
*/

CREATE TABLE [dbo].[AffUserLoginInfo](
	[AffId] [int] NOT NULL,
	[IP] [nvarchar](25) NOT NULL,
	[DeviceInfo] [nvarchar](100) NOT NULL,
	[FailedLoginCount] [tinyint] NULL,
	[LastLoginDate] [datetime] NULL,
    [VerificationCount] [tinyint] NULL,
	[LastVerificationDate] [datetime] NULL,
 CONSTRAINT [PK_AffUserLoginInfo] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[IP] ASC,
	[DeviceInfo] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO