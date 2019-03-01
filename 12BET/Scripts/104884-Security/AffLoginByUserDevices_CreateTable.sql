CREATE TABLE [dbo].[AffLoginByUserDevices](
	[AffId] [int] NOT NULL,
	[IpAddress] [nvarchar](25) NOT NULL,
	[DeviceInfo] [nvarchar](100) NOT NULL,
	[FailedLoginCount] [tinyint] NULL,
	[LastLoginDate] [datetime] NULL,
    [VerificationCount] [tinyint] NULL,
	[LastVerificationDate] [datetime] NULL,
 CONSTRAINT [PK_AffLoginByUserDevices] PRIMARY KEY CLUSTERED 
(
	[AffId] ASC,
	[IpAddress] ASC,
	[DeviceInfo] ASC
) WITH (PAD_INDEX  = OFF, STATISTICS_NORECOMPUTE  = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS  = ON, ALLOW_PAGE_LOCKS  = ON) ON [DATA]
) ON [DATA]

GO