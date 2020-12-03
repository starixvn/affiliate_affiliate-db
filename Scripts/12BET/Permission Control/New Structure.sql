/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20201201@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: New structure: user permission control
*/
USE Affiliate_12BET
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
	,DisplayName	NVARCHAR(500)
	,Description	NVARCHAR(1000)
	,ParentId		SMALLINT
	,AllParentIds	VARCHAR(1000)
	,CreatedDate	DATETIME CONSTRAINT DF_Functions_CreatedDate DEFAULT (GETDATE())
	,UpdatedDate	DATETIME CONSTRAINT DF_Functions_UpdatedDate DEFAULT (GETDATE())
	,Creator		INT
	,OrderId		SMALLINT
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
VALUES ('Management'),('Exe. Settlement'),('Exe. Risk Team'),('Exe. Marketing'),('Asst. Marketing'),('IT User')
GO

INSERT INTO dbo.Functions (FuncName,OrderId,DisplayName,Description)
VALUES ('[Home]'				,  1, 'Home page', 'Home')
		,('[Customer]'			,  2, 'Customer page', 'Customer')
		,('[AffAccountStatus]'	,  3, 'Account Status', 'Affiliate Account Status')
		,('[AffPassword]'		,  4, 'Affiliate Password', 'Affiliate Password')
		,('[SecurityQA]'		,  5, 'Security Question and Answer', 'Security Q&A')
		,('[AffPhone]'			,  6, 'Phone Number', 'Affiliate Phone Number')
		,('[AffEmail]'			,  7, 'Email Address', 'Affiliate Email')
		,('[AffMarket]'			,  8, 'Language Admendment', 'Affiliate Market')
		,('[AffPaymentInfo]'	,  9, '12BET Player Account', 'Affiliate Payment Information')
		,('[AffWebURL]'			, 10, 'Website URL', 'Affiliate Website URL')
		,('[AffPlayerDetail]'	, 11, 'Active Player Detail', 'Affiliate Players Detail')
		,('[AffTurnover]'		, 12, 'Turnover', 'Affiliate Turnover')
		,('[AffAdjustment]'		, 13, 'Adjustment', 'Affiliate Adjustment')
		,('[Note]'				, 14, 'Note', 'Manage Notes')
		,('[AssignCommGroup]'	, 15, 'Commission Group', 'Assign Affiliate into Commission Group')
		,('[CommissionGroup]'	, 16, 'Commission Group Setting', 'Commission Group')
		,('[AffMemberName]'		, 17, 'Signup Members', 'Customer')
		,('[AffReport]'			, 18, 'Affiliate Report', 'Affiliate Report')
		,('[ExportExcel]'		, 19, 'Export Excel Report', 'Export Excel')
		,('[Affiliate]'			, 20, 'Affiliate Info', 'Affiliate')
		,('[Payment]'			, 21, 'Payment Request', 'Payment')
		,('[AffMember]'			, 22, 'Member Menu', 'Member')
		,('[AffMemberDetail]'	, 23, 'Member', 'Member')
		,('[ActiveMembers]'		, 24, 'Active member', 'Member')
		,('[Media]'				, 25, 'Media Gallery', 'Media')
		,('[HotNews]'			, 26, 'Hot News', 'Message')
		,('[AffEx.Rate]'		, 27, 'Ex. Rate', 'Ex.Rate')
		,('[Domain]'			, 28, 'Domain Control', 'Domain')
		,('[UserControl]'		, 29, 'Admin Role', 'User Control')
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

DECLARE @FunctionPermission TABLE (FuncName VARCHAR(100), Management TINYINT, Settlement TINYINT, Risk TINYINT, Marketing TINYINT, AsstMarketing TINYINT, ITUser TINYINT)
INSERT INTO @FunctionPermission (FuncName, Management, Settlement, Risk, Marketing, AsstMarketing, ITUser)
VALUES
('[SecurityQA]'			, 3, 0, 0, 0, 0, 1)
,('[AffPhone]'			, 3, 0, 0, 1, 0, 1)
,('[AffEmail]'			, 3, 0, 0, 1, 0, 1)
,('[AffPaymentInfo]'	, 3, 0, 1, 0, 0, 1)
,('[AffWebURL]'			, 3, 0, 0, 1, 1, 1)
,('[AssignCommGroup]'	, 3, 0, 1, 1, 0, 1)
,('[AffMarket]'			, 3, 0, 1, 1, 0, 1)
,('[AffTurnover]'		, 3, 0, 0, 0, 0, 1)
,('[Note]'				, 3, 1, 1, 1, 0, 1)
,('[AffAdjustment]'		, 3, 1, 1, 1, 0, 1)
,('[AffAccountStatus]'	, 3, 1, 1, 1, 0, 1)
,('[AffReport]'			, 3, 0, 1, 1, 0, 1)
,('[ExportExcel]'		, 3, 0, 1, 0, 0, 1)
,('[AffPlayerDetail]'	, 3, 1, 1, 1, 0, 1)
,('[AffMemberName]'		, 3, 1, 1, 1, 0, 1)
,('[AffPassword]'		, 3, 0, 0, 0, 0, 1)
,('[Affiliate]'			, 3, 1, 1, 1, 1, 1)
,('[Payment]'			, 3, 3, 1, 1, 1, 1)
,('[CommissionGroup]'	, 3, 1, 1, 1, 0, 1)
,('[AffMember]'			, 3, 1, 1, 1, 0, 1)
,('[AffMemberDetail]'	, 3, 1, 1, 1, 0, 1)
,('[ActiveMembers]'		, 3, 1, 1, 1, 0, 1)
,('[AffEx.Rate]'		, 3, 1, 1, 1, 1, 1)
,('[HotNews]'			, 3, 1, 1, 3, 1, 1)
,('[Domain]'			, 3, 1, 3, 1, 1, 1)
,('[UserControl]'		, 3, 0, 0, 0, 0, 1)
,('[Home]'				, 3, 3, 3, 3, 3, 1)
,('[Customer]'			, 3, 3, 3, 3, 3, 1)
,('[Media]'				, 3, 1, 1, 1, 1, 1)
GO

INSERT INTO dbo.RoleFunction (RoleId, FuncId, Policy)
SELECT r.RoleId, f.FuncId, t.Policy
FROM @FunctionPermission fp
	INNER JOIN dbo.Functions f WITH (NOLOCK) ON fp.FuncName = f.FuncName
	CROSS APPLY (
		SELECT 'Management' AS RoleName, fp.Management AS Policy
		UNION ALL SELECT 'Exe. Settlement', fp.Settlement
		UNION ALL SELECT 'Exe. Risk Team', fp.Risk
		UNION ALL SELECT 'Exe. Marketing', fp.Marketing
		UNION ALL SELECT 'Asst. Marketing', fp.AsstMarketing
		UNION ALL SELECT 'IT User', fp.ITUser
	) t
	INNER JOIN dbo.Roles r WITH (NOLOCK) ON t.RoleName = r.RoleName
ORDER BY r.RoleId, f.FuncId
GO

INSERT INTO dbo.RoleMarket (RoleId,MarketId)
SELECT r.RoleId, m.MarketId
FROM dbo.Roles r WITH (NOLOCK)
	CROSS JOIN dbo.Market m WITH (NOLOCK)
WHERE r.RoleName <> 'Asst. Marketing'
	AND m.MarketId NOT IN ('es-ES', 'ja-JP')
ORDER BY r.RoleId, m.MarketId
GO

INSERT INTO dbo.Users (UserName,RoleId,FirstName,LastName,UserPwd)
VALUES ('AAstarix01',1,'Starix01','','56E8A2D78170E87C928E480797CC73')
		,('AAstarix02',1,'Starix02','','56E8A2D78170E87C928E480797CC73')
GO

INSERT INTO dbo.UserFunction (CustId,FuncId,Policy)
SELECT u.CustId, rf.FuncId, rf.Policy
FROM Users u WITH (NOLOCK)
	INNER JOIN dbo.RoleFunction rf WITH (NOLOCK) ON u.RoleId = rf.RoleId
GO

INSERT INTO dbo.UserMarket (CustId,MarketId)
SELECT u.CustId, rm.MarketId
FROM Users u WITH (NOLOCK)
	INNER JOIN dbo.RoleMarket rm WITH (NOLOCK) ON u.RoleId = rm.RoleId
GO

DECLARE @MessageContent NVARCHAR(2000)
SELECT  @MessageContent = N'You are not authorized on this function!'
INSERT INTO dbo.Messages (MessageId,MessageTypeId,Description,MessageContentEN,MessageContentCS,MessageContentCH,MessageContentID,MessageContentVN,MessageContentTH,MessageContentKO,MessageContentES,MessageContentJP,MessageContentHIEN,MessageContentENEURO)
VALUES (1401, 14, @MessageContent, @MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent,@MessageContent)
GO