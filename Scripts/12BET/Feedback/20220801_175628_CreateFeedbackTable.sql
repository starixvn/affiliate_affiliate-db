/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20220811@Eddie
	DB: 	 DBAFF12BET-Affiliate_12BET
	Task: 	 create table for Feedback [RedmineId : #175628]
*/
CREATE TABLE [dbo].[AffFeedback](
	[FId] [int] IDENTITY(1,1) NOT NULL,
	[AffId] [int] NULL,
	[SentDate] [datetime] NULL,
	[RateId] [int] NULL,
	[Message] [nvarchar](4000) NOT NULL,
 CONSTRAINT [PK_AffFeedback] PRIMARY KEY CLUSTERED 
(
	[FId] ASC
),
 INDEX [INC_AffFeedback] NONCLUSTERED 
(
	[AffId]    ASC,
	[SentDate] ASC
)
) ON [DATA]
GO

ALTER TABLE [dbo].[AffFeedback] ADD  CONSTRAINT [DF_Affiliate_Feedback_SentDate]  DEFAULT (getdate()) FOR [SentDate]
GO
