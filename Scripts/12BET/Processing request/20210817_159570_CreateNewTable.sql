/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210818@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new table for Processing Request [RedmineId : #159570]
*/

USE Affiliate_12BET
GO

CREATE TABLE dbo.ProcessingRequest
(
	RequestId				INT IDENTITY(1, 1) 
	,AffId					INT
	,Creator				INT
	,CreationDate			DATETIME
	,LastModified			DATETIME
	,SubmittedDate			DATETIME
	,Deadline				DATETIME
	,Approver				INT
	,ApprovalDate			DATETIME
	,Status					VARCHAR(30)
	,MarketID				NVARCHAR(10)
	,PreferredPayment		VARCHAR(20) --Play for 12bet play, bank for Wire
	,Player_Username		VARCHAR(100)
	,Wire_BankName			NVARCHAR(100)
	,Wire_BankAddress		NVARCHAR(200)
	,Wire_SwiftCode			NVARCHAR(50)
	,Wire_AccountName		NVARCHAR(100)
	,Wire_AccountNo			VARCHAR(100)
	,PromotionMethod		NVARCHAR(1000)
	,WebRank				NVARCHAR(1000)
	,WebRegDate				NVARCHAR(1000)
	,WebSMLanguage			NVARCHAR(1000)
	,ServerCountry			NVARCHAR(1000)
	,WebSMQuality			NVARCHAR(1000)
	,WebSMType				NVARCHAR(1000)
	,WebAdvAff				NVARCHAR(1000)
	,TargetMarket			NVARCHAR(1000)
	,AgentName				NVARCHAR(1000)
	,ContactModeTime		NVARCHAR(1000)
	,Remark					NVARCHAR(1000)
	,CONSTRAINT PK_ProcessingRequest PRIMARY KEY CLUSTERED (RequestId)
) ON [ReportData]

CREATE NONCLUSTERED INDEX IX_AffId_Status ON ProcessingRequest(AffId, Status) ON [ReportData]




