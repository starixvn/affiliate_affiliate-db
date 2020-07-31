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
	CustId				INT IDENTITY (1,1) NOT NULL
	,UserName			VARCHAR(50) NOT NULL
	,RoleId				TINYINT
	,FirstName			NVARCHAR(50)
	,LastName			NVARCHAR(50)
	,UserPwd			VARCHAR(100)
	,UserSalt			VARCHAR(100)
	,PwdExpiry			DATETIME
	,CreatedDate		DATETIME CONSTRAINT DF_Users_CreatedDate DEFAULT (GETDATE())
	,Creator			INT
	,LastLoginIP		NVARCHAR(50)
	,LastLoginDate		DATETIME
	,FailedLoginCount	TINYINT CONSTRAINT DF_Users_FailedLoginCount DEFAULT ((0))
	,Closed				BIT CONSTRAINT DF_Users_Closed DEFAULT ((0))
	,IsDeleted			BIT CONSTRAINT DF_Users_IsDeleted DEFAULT ((0))
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
	,Policy			TINYINT
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
	,Policy			TINYINT
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
		,('[Affiliate]', 'Affiliate')
		,('[Member]', 'Member')
		,('[Report]', 'Report')
		,('[MediaGallery]', 'Media Gallery')
		,('[Message]', 'Message')
		,('[ExRate]', 'Ex.Rate')
		,('[Domain]', 'Domain')
		,('[AdminRole]', 'Admin Role')
GO

INSERT INTO dbo.RoleFunction (RoleId,FuncId,Policy)
SELECT RoleId, FuncId, 3
FROM Roles r WITH (NOLOCK)
	CROSS JOIN Functions f WITH (NOLOCK)
GO

INSERT INTO dbo.Users (UserName,RoleId,FirstName,LastName,UserPwd, UserSalt)
VALUES ('pgmPercy',1,'Percy','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAHubert',1,'Hubert','Duong','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AASteve',1,'Steve','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAMaia',1,'Maia','Le','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')

		,('AAHubert01',2,'Hubert','Duong','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AASteve01',2,'Steve','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAMaia01',2,'Maia','Le','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')

		,('AAHubert02',3,'Hubert','Duong','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AASteve02',3,'Steve','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAMaia02',3,'Maia','Le','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')

		,('AAHubert03',4,'Hubert','Duong','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AASteve03',4,'Steve','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAMaia03',4,'Maia','Le','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')

		,('AAHubert04',5,'Hubert','Duong','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AASteve04',5,'Steve','Nguyen','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
		,('AAMaia04',5,'Maia','Le','56E8A2D78170E87C928E480797CC73', 'SIymwTYtl4dVMSRM5w==')
GO

INSERT INTO dbo.UserFunction (CustId,FuncId,Policy)
SELECT CustId, FuncId, 3
FROM Users u WITH (NOLOCK)
	CROSS JOIN dbo.Functions f WITH (NOLOCK)
GO

INSERT INTO dbo.RoleMarket (RoleId,MarketId,Policy)
SELECT RoleId, MarketId, 3
FROM Roles r WITH (NOLOCK)
	CROSS JOIN dbo.Market m WITH (NOLOCK)
GO

INSERT INTO dbo.UserMarket (CustId,MarketId,Policy)
SELECT CustId, MarketId, 3
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