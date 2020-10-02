USE Affiliate_12BET
GO

DROP TABLE dbo.Users
GO
DROP TABLE dbo.Roles
GO
DROP TABLE dbo.Functions
GO
DROP TABLE dbo.RoleFunction
GO
DROP TABLE dbo.UserFunction
GO
DROP TABLE dbo.RoleMarket
GO
DROP TABLE dbo.UserMarket
GO

-- 1. New tables
CREATE TABLE dbo.Users
(
	CustId				INT IDENTITY (10000000, 1) NOT NULL
	,UserName			VARCHAR(50) NOT NULL
	,RoleId				TINYINT
	,FirstName			NVARCHAR(50)
	,LastName			NVARCHAR(50)
	,UserPwd			VARCHAR(100)
	,PwdExpiry			DATETIME
	,CreatedDate		DATETIME CONSTRAINT DF_Users_CreatedDate DEFAULT (GETDATE())
	,Creator			INT
	,LastLoginIP		NVARCHAR(50)
	,LastLoginDate		DATETIME
	,FailedLoginCount	TINYINT CONSTRAINT DF_Users_FailedLoginCount DEFAULT ((0))
	,Closed				BIT CONSTRAINT DF_Users_Closed DEFAULT ((0))
	,IsDeleted			BIT CONSTRAINT DF_Users_IsDeleted DEFAULT ((0))
	,IsRoleFunctionDefault	BIT CONSTRAINT DF_Users_IsRoleFunctionDefault DEFAULT ((0))
	,IsRoleMarketDefault	BIT CONSTRAINT DF_Users_IsRoleMarketDefault DEFAULT ((0))
	,CONSTRAINT PK_Users PRIMARY KEY
	(
		CustId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE UNIQUE NONCLUSTERED INDEX IX_UserName ON dbo.Users (UserName) ON [DATA]
GO

CREATE TABLE dbo.Roles
(
	RoleId			SMALLINT IDENTITY (1,1) NOT NULL
	,RoleName		VARCHAR(100) NOT NULL
	,Description	NVARCHAR(1000)
	,CreatedDate	DATETIME CONSTRAINT DF_Roles_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_Roles_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_Roles PRIMARY KEY
	(
		RoleId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE TABLE dbo.Functions
(
	FuncId			SMALLINT IDENTITY (1,1) NOT NULL
	,FuncName		VARCHAR(100) NOT NULL
	,Description	NVARCHAR(1000)
	,ParentId		SMALLINT
	,AllParentIds	VARCHAR(1000)
	,CreatedDate	DATETIME CONSTRAINT DF_Functions_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_Functions_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_Functions PRIMARY KEY
	(
		FuncId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE TABLE dbo.RoleFunction
(
	RoleId			SMALLINT NOT NULL
	,FuncId			SMALLINT NOT NULL
	,Policy			TINYINT
	,CreatedDate	DATETIME CONSTRAINT DF_RoleFunction_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_RoleFunction_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_RoleFunction PRIMARY KEY
	(
		RoleId ASC
		,FuncId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE TABLE dbo.UserFunction
(
	CustId			INT NOT NULL
	,FuncId			SMALLINT NOT NULL
	,Policy			TINYINT
	,CreatedDate	DATETIME CONSTRAINT DF_UserFunction_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_UserFunction_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_UserFunction PRIMARY KEY
	(
		CustId ASC
		,FuncId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE TABLE dbo.RoleMarket
(
	RoleId			SMALLINT NOT NULL
	,MarketId		NVARCHAR(10) NOT NULL
	,CreatedDate	DATETIME CONSTRAINT DF_RoleMarket_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_RoleMarket_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_RoleMarket PRIMARY KEY
	(
		RoleId ASC
		,MarketId ASC
	) ON [DATA]
) ON [DATA]
GO

CREATE TABLE dbo.UserMarket
(
	CustId			INT NOT NULL
	,MarketId		NVARCHAR(10) NOT NULL
	,CreatedDate	DATETIME CONSTRAINT DF_UserMarket_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_UserMarket_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,CONSTRAINT PK_UserMarket PRIMARY KEY
	(
		CustId ASC
		,MarketId ASC
	) ON [DATA]
) ON [DATA]
GO

-- 2. Intialize data
INSERT INTO dbo.Roles (RoleName)
VALUES ('Management'),('Exe. Settlement'),('Exe. Risk Team'),('Exe. Marketing'),('Ast. Marketing')
GO

INSERT INTO dbo.Functions (FuncName,Description)
VALUES ('[Home]', 'Home')
		,('[Customer]', 'Customer')
		,('[AffMemberName]', 'Customer')
		,('[Affiliate]', 'Affiliate')
		,('[AffReport]', 'Affiliate Report')
		,('[Media]', 'Media')
		,('[HotNews]', 'Message')
		,('[AffEx.Rate]', 'Ex.Rate')
		,('[Domain]', 'Domain')
		,('[UserControl]', 'User Control')
		,('[Payment]', 'Payment')
		,('[CommissionGroup]', 'Commission Group')
		,('[AssignCommGroup]', 'Assign Affiliate into Commission Group')
		,('[Note]', 'Manage Notes')
		,('[SecurityQA]', 'Security Q&A')
		,('[MemberEmail]', 'Member''s Email')
		,('[AffPhone]', 'Affiliate Phone Number')
		,('[AffEmail]', 'Affiliate Email')
		,('[AffPaymentInfo]', 'Affiliate Payment Information')
		,('[AffWebURL]', 'Affiliate Website URL')
		,('[AffMarket]', 'Affiliate Market')
		,('[AffTurnover]', 'Affiliate Turnover')
		,('[AffAdjustment]', 'Affiliate Adjustment')
		,('[AffAccountStatus]', 'Affiliate Account Status')
		,('[AffPlayerDetail]', 'Affiliate Players Detail')
		,('[AffMember]', 'Member')
		,('[AffMemberDetail]', 'Member')
		,('[ActiveMembers]', 'Member')
		,('[ExportExcel]', 'Export Excel')
		,('[AffPassword]', 'Affiliate Password')
GO

UPDATE dbo.Functions WITH (ROWLOCK)
SET ParentId = FuncId
GO

UPDATE c
SET c.ParentId = p.FuncId
FROM dbo.Functions c WITH (ROWLOCK)
	INNER JOIN dbo.Functions p WITH (NOLOCK)
		ON c.FuncName IN ('[AffMemberDetail]', '[ActiveMembers]') AND p.FuncName = '[AffMember]'
GO

UPDATE dbo.Functions WITH (ROWLOCK)
SET AllParentIds = CONVERT(VARCHAR(1000), ParentId)
GO

INSERT INTO dbo.RoleFunction (RoleId,FuncId,Policy)
SELECT RoleId, FuncId, 3
FROM Roles r WITH (NOLOCK)
	CROSS JOIN Functions f WITH (NOLOCK)
GO

INSERT INTO dbo.Users (UserName,RoleId,FirstName,LastName,UserPwd)
VALUES ('sa'			,1,'',''			,'56E8A2D78170E87C928E480797CC73')
		,('pgmPercy'	,1,'Percy','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAHubert'	,1,'Hubert','Duong'	,'56E8A2D78170E87C928E480797CC73')
		,('AASteve'		,1,'Steve','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAMaia'		,1,'Maia','Le'		,'56E8A2D78170E87C928E480797CC73')
		,('AAKevin'		,1,'Kevin','Nguyen'	,'56E8A2D78170E87C928E480797CC73')

		,('AAHubert01'	,2,'Hubert','Duong'	,'56E8A2D78170E87C928E480797CC73')
		,('AASteve01'	,2,'Steve','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAMaia01'	,2,'Maia','Le'		,'56E8A2D78170E87C928E480797CC73')
		,('AAKevin01'	,2,'Kevin','Nguyen'	,'56E8A2D78170E87C928E480797CC73')

		,('AAHubert02'	,3,'Hubert','Duong'	,'56E8A2D78170E87C928E480797CC73')
		,('AASteve02'	,3,'Steve','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAMaia02'	,3,'Maia','Le'		,'56E8A2D78170E87C928E480797CC73')
		,('AAKevin02'	,3,'Kevin','Nguyen'	,'56E8A2D78170E87C928E480797CC73')

		,('AAHubert03'	,4,'Hubert','Duong'	,'56E8A2D78170E87C928E480797CC73')
		,('AASteve03'	,4,'Steve','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAMaia03'	,4,'Maia','Le'		,'56E8A2D78170E87C928E480797CC73')
		,('AAKevin03'	,4,'Kevin','Nguyen'	,'56E8A2D78170E87C928E480797CC73')

		,('AAHubert04'	,5,'Hubert','Duong'	,'56E8A2D78170E87C928E480797CC73')
		,('AASteve04'	,5,'Steve','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
		,('AAMaia04'	,5,'Maia','Le'		,'56E8A2D78170E87C928E480797CC73')
		,('AAKevin04'	,5,'Kevin','Nguyen'	,'56E8A2D78170E87C928E480797CC73')
GO

INSERT INTO dbo.UserFunction (CustId,FuncId,Policy)
SELECT CustId, FuncId, 3
FROM Users u WITH (NOLOCK)
	CROSS JOIN dbo.Functions f WITH (NOLOCK)
GO

INSERT INTO dbo.RoleMarket (RoleId,MarketId)
SELECT RoleId, MarketId
FROM Roles r WITH (NOLOCK)
	CROSS JOIN dbo.Market m WITH (NOLOCK)
GO

INSERT INTO dbo.UserMarket (CustId,MarketId)
SELECT CustId, MarketId
FROM Users u WITH (NOLOCK)
	CROSS JOIN dbo.Market m WITH (NOLOCK)
GO

/*
DECLARE @MessageContent NVARCHAR(2000)
SELECT  @MessageContent = N'You are not authorized on this function!'
INSERT INTO dbo.Messages (MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO)
VALUES (1401, 14, '', @MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent)
GO
*/