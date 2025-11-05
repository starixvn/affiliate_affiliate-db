/*<info serverAlias="DB12B-bodb_12B" ></info>*/
/*  
	Created: 20250804@Sally
	DB: DB12B-bodb_12B
	Task: Cover Abnormal players [RedmineID: #234932]
		- Add table Tag, Add column TagList to Customer
		- Insert initial Tag data on API_TimeTracker table
*/
USE bodb_12B
GO
CREATE TABLE [dbo].[Tag](
	[Id] [int] NOT NULL,
	[TagName] [varchar](45) NOT NULL,
	[Description] [varchar](80) NULL,
	[Status] [int] NOT NULL,
	[UpdateTime] [datetime] NOT NULL,
	[IsAbnormal] [tinyint] NOT NULL,
 CONSTRAINT [PK_Tag] PRIMARY KEY CLUSTERED 
(
	[Id] ASC
)WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON, OPTIMIZE_FOR_SEQUENTIAL_KEY = OFF) ON [SettingData]
) ON [SettingData]
GO
ALTER TABLE dbo.Customer
ADD [TagList] nvarchar(MAX) NULL
	,[LastTagUpdateTime] datetime NULL;

GO
-- Insert initial Tag data on API_TimeTracker table
DELETE FROM dbo.API_TimeTracker WITH(UPDLOCK) WHERE DataSource = 'Tag';
GO
INSERT INTO dbo.API_TimeTracker (DataSource, CalledTime, KeyValue)
SELECT DataSource,'2025-08-12 00:00:00' as CalledTime, KeyValue
FROM (
	SELECT 'Tag'AS DataSource,	'2025-02-12T00:00:00.000' AS KeyValue
)t 