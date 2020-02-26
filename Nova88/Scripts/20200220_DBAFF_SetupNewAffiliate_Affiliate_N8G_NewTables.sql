USE Affiliate_N8G
GO

CREATE TABLE dbo.Deductions
(
	DeductionId	TINYINT NOT NULL,
	DeductionName VARCHAR(50),
	DeductedPercentage DECIMAL(9,8),
	IsTest BIT CONSTRAINT [DF_Deductions_IsTest] DEFAULT((0)),
	IsDeleted BIT CONSTRAINT [DF_Deductions_IsDeleted] DEFAULT((0)),
	CONSTRAINT [PK_Deductions] PRIMARY KEY CLUSTERED
	(
		DeductionId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.CommGroup
(
	GroupId INT NOT NULL,
	GroupName NVARCHAR(100),
	Description NVARCHAR(100),
	Creator INT,
	CreatedDate DATETIME CONSTRAINT [DF_CommGroup_CreatedDate] DEFAULT (GETDATE()),
	IsDeleted BIT,
	CONSTRAINT [PK_CommGroup] PRIMARY KEY CLUSTERED
	(
		GroupId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.AffType
(
	TypeId TINYINT NOT NULL,
	Name NVARCHAR(100),
	Description NVARCHAR(250),
	CreatedDate DATETIME CONSTRAINT [DF_AffType_CreatedDate] DEFAULT (GETDATE()),
	Creator INT,
	IsShown BIT CONSTRAINT [DF_AffType_IsShown] DEFAULT ((0)),
	CONSTRAINT [PK_AffType] PRIMARY KEY CLUSTERED
	(
		TypeId ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.LandingPage
(
	PageId SMALLINT IDENTITY(1,1) NOT NULL,
	PageName NVARCHAR(200),
	PageCode NVARCHAR(100),
	IsDeleted BIT CONSTRAINT [DF_LandingPage_IsDeleted] DEFAULT ((0)),
	CONSTRAINT [PK_LandingPage] PRIMARY KEY CLUSTERED
	(
		PageId ASC
	) ON SettingData
) ON SettingData
GO

/*
	Setting
*/
CREATE TABLE dbo.TierSetting
(
	GroupId INT NOT NULL,
	TierId INT NOT NULL,
	MinAmount MONEY,
	MaxAmount MONEY,
	MinAM INT,
	MaxAM INT,
	Commission DECIMAL(9,8),
	CONSTRAINT [PK_TierSetting] PRIMARY KEY CLUSTERED
	(
		GroupId ASC,
		TierId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.TierSettingHistory
(
	GroupId INT NOT NULL,
	MonthDate DATETIME NOT NULL,
	TierId INT NOT NULL,
	MinAmount MONEY,
	MaxAmount MONEY,
	MinAM INT,
	MaxAM INT,
	Commission DECIMAL(9,8),
	CONSTRAINT [PK_TierSettingHistory] PRIMARY KEY NONCLUSTERED
	(
		GroupId ASC,
		MonthDate ASC,
		TierId ASC
	) ON SettingData
) ON SettingData
GO

CREATE CLUSTERED INDEX CIX_MonthDate_GroupId ON dbo.TierSettingHistory (MonthDate, GroupId) ON SettingData
GO

CREATE TABLE dbo.DeductionSetting
(
	GroupId INT NOT NULL,
	DeductionId TINYINT NOT NULL,
	ProductId INT NOT NULL,
	GroupProductId INT,
	DeductedPercentage DECIMAL(9,8),
	NextGroupProductId INT,
	NextDeductedPercentage DECIMAL(9,8),
	CONSTRAINT [PK_DeductionSetting] PRIMARY KEY CLUSTERED
	(
		GroupId ASC,
		DeductionId ASC,
		ProductId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.DeductionSettingHistory
(
	GroupId INT NOT NULL,
	MonthDate DATETIME NOT NULL,
	DeductionId TINYINT NOT NULL,
	ProductId INT NOT NULL,
	GroupProductId INT,
	DeductedPercentage DECIMAL(9,8),
	CONSTRAINT [PK_DeductionSettingHistory] PRIMARY KEY NONCLUSTERED
	(
		GroupId ASC,
		MonthDate ASC,
		DeductionId ASC,
		ProductId ASC
	) ON SettingData
) ON SettingData
GO

CREATE CLUSTERED INDEX CIX_MonthDate_GroupId ON dbo.DeductionSettingHistory (MonthDate, GroupId, DeductionId) ON SettingData
GO

CREATE TABLE dbo.AffInfo
(
	AffId INT IDENTITY(1,1) NOT NULL,
	UserName NVARCHAR(30),
	UserName2 NVARCHAR(30),
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	GroupId	INT,
	Status VARCHAR(30),
	ApprovedDate DATETIME,
	IsClosed BIT CONSTRAINT [DF_AffInfo_IsClosed] DEFAULT ((0)),
	Currency INT,
	RegisteredDate DATETIME,
	Email NVARCHAR(50),
	Password VARCHAR(40),
	AffType TINYINT,
	IsPageEnabled BIT,
	Level TINYINT,
	IsLocked BIT,
	CasinoJoinedDate DATETIME,
	ForceChangePass BIT,
	SecretKey VARCHAR(50),
	CONSTRAINT [PK_AffInfo] PRIMARY KEY CLUSTERED
	(
		AffId ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.AffDetail
(
	AffId INT NOT NULL,
	UserName VARCHAR(30) NOT NULL,
	SiteURL VARCHAR(100) NOT NULL,
	MoreSiteURLs VARCHAR(1000),
	PreferredLanguage VARCHAR(11),
	Gender BIT,
	Address NVARCHAR(250),
	Postal NVARCHAR(50),
	City NVARCHAR(250),
	State NVARCHAR(50),
	Country NVARCHAR(50),
	Phone VARCHAR(50),
	MobilePhone VARCHAR(50),
	Fax VARCHAR(50),
	Question NVARCHAR(300),
	Answer NVARCHAR(300),
	PreferredPayment VARCHAR(20),
	Player_IBCCustID INT,
	Player_Username VARCHAR(30),
	Player_Currency INT,
	Neteller_AccountID VARCHAR(50),
	Moneybookers_Email NVARCHAR(50),
	Wire_BankName NVARCHAR(100),
	Wire_BankAddress NVARCHAR(200),
	Wire_SwiftCode NVARCHAR(50),
	Wire_AccountName NVARCHAR(100),
	Wire_AccountNo VARCHAR(100),
	Cheque_FullName NVARCHAR(200),
	Cheque_Address NVARCHAR(200),
	Cheque_City NVARCHAR(50),
	Cheque_State NVARCHAR(50),
	Cheque_Postal NVARCHAR(50),
	Cheque_Country NVARCHAR(50),
	BonusCode VARCHAR(20),
	LastLoginDate DATETIME,
	LastLoginIP NVARCHAR(20),
	LoginCount TINYINT,
	ValidCode NVARCHAR(30),
	CodeExpiry DATETIME,
	MailOption BIT,
	NoSiteDesc NVARCHAR(1000),
	ContactApps NVARCHAR(2000),
	QuestionID TINYINT,
	CONSTRAINT [PK_AffDetail] PRIMARY KEY CLUSTERED
	(
		AffId ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.AffGroupHistory
(
	AffId INT NOT NULL,
	MonthDate DATETIME NOT NULL,
	GroupId INT NOT NULL,
	CONSTRAINT [PK_AffGroupHistory] PRIMARY KEY CLUSTERED
	(
		AffId ASC,
		MonthDate ASC,
		GroupId ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.AffFunctionInfo
(
	[FuncId] [int] IDENTITY(100000,1) NOT NULL,
	[FuncName] [nvarchar](50) NULL,
	[FuncNote] [nvarchar](2000) NULL,
	[FuncDesc] [nvarchar](50) NULL,
	[FuncRender] [tinyint] NULL,
	[CreateDate] [datetime] NOT NULL CONSTRAINT [DF_AffFunctionInfo_CreateDate]  DEFAULT (GETDATE()),
	[ModifyDate] [datetime] NOT NULL CONSTRAINT [DF_AffFunctionInfo_ModifyDate]  DEFAULT (GETDATE()),
	[DisplayOrder] [tinyint] NULL CONSTRAINT [DF_AffFunctionInfo_DisplayOrder]  DEFAULT ((7)),
	[Creator] [int] NULL,
	[ParentId] [int] NULL,
	[FileNames] [varchar](2000) NULL
	CONSTRAINT [PK_AffFunctionInfo] PRIMARY KEY CLUSTERED 
	(
		[FuncId] ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.AffPayout
(
	RefId BIGINT IDENTITY(2000000001, 1) NOT NULL,
	AffId INT,
	IBCCustId INT,
	UserName VARCHAR(30),
	IBCUserName VARCHAR(30),
	Amount MONEY,
	AffPayout MONEY,
	AffCurrency INT,
	AffExRate FLOAT,
	MemberCurrency INT,
	MemberExRate FLOAT,
	TransDate DATETIME,
	CompletedDate DATETIME,
	Status VARCHAR(50),
	AdminDesc NVARCHAR(300),
	AffDesc NVARCHAR(300),
	CONSTRAINT [PK_AffPayout] PRIMARY KEY NONCLUSTERED
	(
		RefId ASC
	) ON AffData
) ON AffData
GO

CREATE CLUSTERED INDEX CIX_AffId ON dbo.AffPayout (AffId, TransDate)
GO

CREATE NONCLUSTERED INDEX IX_TransDate ON dbo.AffPayout (TransDate) INCLUDE (Amount)
GO

CREATE TABLE dbo.AffTrans
(
	TransId	BIGINT IDENTITY(1, 1) NOT NULL,
	AffId INT,
	TransDate DATETIME,
	CompletedDate DATETIME,
	Amount MONEY,
	Status VARCHAR(50),
	Description	NVARCHAR(300),
	Creator INT,
	Currency INT,
	ActualRate FLOAT,
	TransType INT,
	RefId BIGINT,
	AffExRate FLOAT,
	CONSTRAINT [PK_AffTrans] PRIMARY KEY NONCLUSTERED
	(
		TransId ASC
	) ON AffData
) ON AffData
GO

CREATE CLUSTERED INDEX CIX_AffId ON dbo.AffTrans (AffId, TransDate, Status)
GO

CREATE NONCLUSTERED INDEX IX_TransDate ON dbo.AffTrans (TransDate) INCLUDE (Amount)
GO

CREATE TABLE dbo.AffLoginInfo
(
	AffId INT NOT NULL,
	LoginSessionId VARCHAR(30) NOT NULL,
	LastLoginDate DATETIME,
	LastLoginIP VARCHAR(50),
	FailedLoginCount TINYINT,
	CONSTRAINT [PK_AffLoginInfo] PRIMARY KEY CLUSTERED
	(
		AffId ASC,
		LoginSessionId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.AffUserLoginInfo
(
	AffId INT NOT NULL,
	IP NVARCHAR(25) NOT NULL,
	DeviceInfo NVARCHAR(100) NOT NULL,
	FailedLoginCount TINYINT,
	LastLoginDate DATETIME,
	VerificationCount TINYINT,
	LastVerificationDate DATETIME,
	CONSTRAINT [PK_AffUserLoginInfo] PRIMARY KEY CLUSTERED
	(
		AffId ASC,
		IP ASC,
		DeviceInfo ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.AffGroupInfo
(
	GroupId INT IDENTITY(1000, 1) NOT NULL,
	GroupName NVARCHAR(50) NOT NULL,
	GroupDesc NVARCHAR(50) NULL,
	CreateDate DATETIME CONSTRAINT [DF_AffGroupInfo_CreateDate] DEFAULT (GETDATE()),
	ModifyDate DATETIME CONSTRAINT [DF_AffGroupInfo_ModifyDate] DEFAULT (GETDATE()),
	DisplayOrder TINYINT,
	Creator INT,
	CONSTRAINT [PK_AffGroupInfo] PRIMARY KEY CLUSTERED
	(
		GroupId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.AffGroupPolicy
(
	GroupId INT NOT NULL,
	FuncId INT NOT NULL,
	Policy TINYINT,
	CreateDate DATETIME CONSTRAINT [DF_AffGroupPolicy_CreateDate] DEFAULT (GETDATE()),
	ModifyDate DATETIME CONSTRAINT [DF_AffGroupPolicy_ModifyDate] DEFAULT (GETDATE()),
	Creator INT,
	CONSTRAINT [PK_AffGroupPolicy] PRIMARY KEY CLUSTERED
	(
		GroupId ASC,
		FuncId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.AffMemberPolicy
(
	CustId INT NOT NULL,
	FuncId INT NOT NULL,
	Policy TINYINT,
	CreateDate DATETIME CONSTRAINT [DF_AffMemberPolicy_CreateDate] DEFAULT (GETDATE()),
	ModifyDate DATETIME CONSTRAINT [DF_AffMemberPolicy_ModifyDate] DEFAULT (GETDATE()),
	Creator INT,
	CONSTRAINT [PK_AffMemberPolicy] PRIMARY KEY CLUSTERED
	(
		CustId ASC,
		FuncId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.Affiliate_User
(
	CustId INT IDENTITY(1000000000, 1) NOT NULL,
	PageAccess NVARCHAR(500),
	CreateDate DATETIME,
	Creator INT,
	GroupId INT,
	Closed BIT,
	LoginCount TINYINT,
	IPLogin VARCHAR(20),
	LastLogged SMALLDATETIME,
	On_SessionId INT,
	UserName VARCHAR(30),
	UserPwd VARCHAR(40),
	RoleId TINYINT,
	PwdExpiry DATETIME,
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	CONSTRAINT [PK_Affiliate_User] PRIMARY KEY CLUSTERED
	(
		CustId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.EmailHistory
(
	MId	INT IDENTITY(1,1) NOT NULL,
	Content	NVARCHAR(4000),
	Sender	NVARCHAR(100),
	Creator	INT,
	AffId	INT,
	AffName	VARCHAR(30),
	Email	NVARCHAR(50),
	Subject	NVARCHAR(2000),
	CreatedDate	DATETIME CONSTRAINT [DF_EmailHistory_CreatedDate] DEFAULT (GETDATE()),
	IP VARCHAR(25),
	Browser	NVARCHAR(100),
	SessionId VARCHAR(200),
	IsDeleted BIT CONSTRAINT [DF_EmailHistory_IsDeleted] DEFAULT ((0)),
	CONSTRAINT [PK_EmailHistory] PRIMARY KEY CLUSTERED
	(
		MId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.Market
(
	MarketId NVARCHAR(10),
	MarketName NVARCHAR(50),
	MarketNativeName NVARCHAR(50),
	ShortedCode NVARCHAR(10),
	DisplayName NVARCHAR(50),
	CONSTRAINT [PK_Market] PRIMARY KEY CLUSTERED
	(
		MarketId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.MemberInfo(
	CustId INT NOT NULL,
	UserName VARCHAR(30) NOT NULL,
	FirstName NVARCHAR(50),
	LastName NVARCHAR(50),
	Email NVARCHAR(50),
	Currency INT,
	ActStatus TINYINT,
	Status TINYINT,
	RegisteredDate DATETIME,
	AffId INT NOT NULL,
	IBCCustId INT,
	IBCUserName VARCHAR(30),
	CreatedDate DATETIME,
	IsRemoved BIT CONSTRAINT [DF_MemberInfo_IsRemoved] DEFAULT ((0)),
	Recommend INT,
	ClickId BIGINT CONSTRAINT [DF_MemberInfo_ClickId] DEFAULT ((0)),
	CONSTRAINT [PK_MemberInfo] PRIMARY KEY CLUSTERED
	(
		CustId ASC
	) ON AffData
) ON AffData
GO

CREATE NONCLUSTERED INDEX IX_AffId ON dbo.MemberInfo (AffId, IBCCustId)
	INCLUDE (UserName, IBCUserName, Currency, FirstName, LastName, Email, RegisteredDate, CreatedDate, IsRemoved) ON AffData
GO

CREATE TABLE dbo.MemberRemoval
(
	IBCCustId INT NOT NULL,
	RemovedDate	DATETIME,
	RemovedBy INT,
	CONSTRAINT [PK_MemberRemoval] PRIMARY KEY CLUSTERED
	(
		IBCCustId ASC
	) ON AffData
) ON AffData
GO

CREATE TABLE dbo.MemberClickDetail
(
	CustId INT NOT NULL,
	ClickId	BIGINT NOT NULL,
	DomainReferrer NVARCHAR(300),
	IBCCustId INT,
	LanguageCode VARCHAR(10),
	SportCode VARCHAR(50),
	URLRedirect NVARCHAR(300),
	URLReferrer NVARCHAR(300),
	DeviceType TINYINT,
	AffID INT,
	CreatedDate DATETIME,
	CONSTRAINT [PK_MemberClickDetail] PRIMARY KEY NONCLUSTERED
	(
		CustId ASC
	) ON ReportData
) ON ReportData
GO

CREATE NONCLUSTERED INDEX IX_AffId ON dbo.MemberClickDetail (AffId)
	INCLUDE (LanguageCode, SportCode, DeviceType) ON ReportData
GO

CREATE CLUSTERED INDEX IX_CreatedDate ON dbo.MemberClickDetail (CreatedDate) ON ReportData
GO

CREATE TABLE dbo.Messages
(
	MessageId INT NOT NULL,
	MessageTypeId SMALLINT,
	Description NVARCHAR(2000),
	MessageContentEN NVARCHAR(2000),
	MessageContentCS NVARCHAR(2000),
	MessageContentCH NVARCHAR(2000),
	MessageContentID NVARCHAR(2000),
	MessageContentVN NVARCHAR(2000),
	MessageContentTH NVARCHAR(2000),
	MessageContentKO NVARCHAR(2000),
	MessageContentES NVARCHAR(2000),
	MessageContentJP NVARCHAR(2000),
	MessageContentHIEN NVARCHAR(2000),
	MessageContentENEURO NVARCHAR(2000),
	CONSTRAINT [PK_Messages] PRIMARY KEY CLUSTERED
	(
		MessageId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.News
(
	MsgId INT IDENTITY(1,1) NOT NULL,
	Message_En NVARCHAR(4000),
	Message_Cn NVARCHAR(4000),
	Message_Tw NVARCHAR(4000),
	Message_Es NVARCHAR(4000),
	Message_Th NVARCHAR(4000),
	Message_Id NVARCHAR(4000),
	Message_Vi NVARCHAR(4000),
	Message_Kr NVARCHAR(4000),
	Message_Jp NVARCHAR(4000),
	Creator INT,
	PostedDate DATETIME,
	Important BIT NOT NULL CONSTRAINT [DF_News_Important] DEFAULT ((0)),
	UpdatedBy INT,
	UpdatedDate DATETIME,
	CONSTRAINT [PK_News] PRIMARY KEY CLUSTERED
	(
		MsgId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.On_User
(
	On_UserId INT IDENTITY(1,1) NOT NULL,
	On_SessionId INT NOT NULL,
	CustId INT,
	Reload_Time DATETIME,
	ServerId INT,
	IP NVARCHAR(20),
	IsKickedOut BIT,
	SubAccId INT,
	NetSessionId VARCHAR(30),
	Country SMALLINT,
	MachineIP INT,
	DomainId INT,
	CONSTRAINT [PK_On_User] PRIMARY KEY CLUSTERED
	(
		On_UserId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.Products
(
	ProductId INT NOT NULL,
	ProductName VARCHAR(100) NOT NULL,
	ProductPrefix VARCHAR(10),
	IsIBC BIT,
	Enabled BIT CONSTRAINT [DF_Products_Enabled] DEFAULT ((1)),
	IsTest BIT CONSTRAINT [DF_Products_IsTest] DEFAULT ((0)),
	EndOfSupportDate SMALLDATETIME,
	ReleasedDate SMALLDATETIME,
	CONSTRAINT [PK_Products] PRIMARY KEY CLUSTERED
	(
		ProductId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.rptAffCommission
(
	MonthDate SMALLDATETIME NOT NULL,
	AffId INT NOT NULL,
	GroupId INT NOT NULL,
	ProductId INT NOT NULL,
	Deposit MONEY,
	Withdrawal MONEY,
	Bonus MONEY,
	Adjustment MONEY,
	Turnover MONEY,
	Winloss MONEY,
	GrossWinloss MONEY,
	NetWinloss MONEY,
	QMTurnover MONEY,
	ActivePlayer INT,
	QualifiedMember INT,
	CommissionRate DECIMAL(9, 8),
	CONSTRAINT [PK_rptAffCommission] PRIMARY KEY CLUSTERED 
	(
		MonthDate ASC,
		AffId ASC,
		GroupId ASC,
		ProductId ASC
	) ON ReportData
) ON ReportData
GO

CREATE NONCLUSTERED INDEX IX_AffId_GroupId_ProductId ON dbo.rptAffCommission
(
	AffId ASC,
	GroupId ASC,
	ProductId ASC
)
INCLUDE (Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss) ON ReportData
GO

CREATE TABLE dbo.rptAffDeduction
(
	MonthDate SMALLDATETIME NOT NULL,
	AffId INT NOT NULL,
	GroupId INT NOT NULL,
	ProductId INT NOT NULL,
	GroupProductId TINYINT,
	DeductionId INT NOT NULL,
	Amount MONEY,
	CONSTRAINT [PK_rptAffDeduction] PRIMARY KEY CLUSTERED
	(
		MonthDate ASC,
		AffId ASC,
		GroupId ASC,
		ProductId ASC,
		DeductionId ASC
	) ON ReportData
) ON ReportData
GO

CREATE NONCLUSTERED INDEX IX_AffId_ProductId ON dbo.rptAffDeduction
(
	AffId ASC,
	ProductId ASC
)
INCLUDE (GroupProductId,DeductionId,Amount) ON ReportData
GO

CREATE TABLE dbo.rptMemberDaily
(
	WinlostDate	SMALLDATETIME,
	AffId INT,
	IBCCustId INT,
	Currency INT,
	ExRate FLOAT,
	AffExRate FLOAT,
	ProductId INT,
	Deposit MONEY,
	Withdrawal MONEY,
	Bonus MONEY,
	Adjustment MONEY,
	Turnover MONEY,
	Winloss MONEY,
	CONSTRAINT [PK_rptMemberDaily] PRIMARY KEY NONCLUSTERED
	(
		WinlostDate ASC,
		IBCCustId ASC,
		ProductId ASC
	) ON ReportData
) ON ReportData
GO

CREATE CLUSTERED INDEX CIX_WinlostDate_AffId_ProductId ON dbo.rptMemberDaily
(
	WinlostDate ASC,
	AffId ASC,
	ProductId ASC
) ON ReportData
GO

CREATE NONCLUSTERED INDEX IX_AffId_ProductId ON dbo.rptMemberDaily
(
	AffId ASC,
	ProductId ASC
)
INCLUDE (Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,AffExRate) ON ReportData
GO

CREATE TABLE dbo.SystemSettings
(
	SID INT IDENTITY(1,1) NOT NULL,
	SName VARCHAR(50),
	SValue VARCHAR(200),
	CONSTRAINT [PK_SystemSettings] PRIMARY KEY CLUSTERED
	(
		SID ASC
	) ON SettingData
) ON SettingData
GO

CREATE NONCLUSTERED INDEX IX_SName ON dbo.SystemSettings (SName) INCLUDE (SValue) ON SettingData
GO

CREATE TABLE dbo.TransType
(
	TypeId SMALLINT,
	TypeName NVARCHAR(50),
	TypeDesc NVARCHAR(50),
	CONSTRAINT [PK_TransType] PRIMARY KEY CLUSTERED 
	(
		TypeId ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.UserLog_RunSP_Detail
(
	LogId INT IDENTITY(1,1) NOT NULL,
	LogTypeId INT,
	LogActionId INT,
	SPName VARCHAR(200),
	UserId INT,
	AffId INT,
	LogDate DATETIME NOT NULL CONSTRAINT [DF_UserLog_RunSP_Detail_LogDate] DEFAULT (GETDATE()),
	OldData	NVARCHAR(MAX),
	NewData	NVARCHAR(MAX),
	IP VARCHAR(50),
	Language VARCHAR(20),
	IsWebCall BIT,
	CONSTRAINT [PK_UserLog_RunSP_Detail] PRIMARY KEY NONCLUSTERED 
	(
		LogId ASC
	) ON LogData
) ON LogData
GO

CREATE CLUSTERED INDEX CIX_LogActionId_LogDate ON dbo.UserLog_RunSP_Detail
(
	LogActionId ASC,
	LogDate ASC
) ON LogData
GO

CREATE NONCLUSTERED INDEX IX_UserId_LogActionId ON dbo.UserLog_RunSP_Detail
(
	UserId ASC,
	LogActionId ASC
) ON LogData
GO

CREATE TABLE dbo.Username_AutoIncrement
(
	Id BIGINT IDENTITY(1,1) NOT NULL,
	PrefixName	NVARCHAR(50),
	SubfixName	BIGINT,
	CONSTRAINT [PK_Username_AutoIncrement] PRIMARY KEY CLUSTERED 
	(
		Id ASC
	) ON SettingData
) ON SettingData
GO

CREATE TABLE dbo.LogAction
(
	ActionId INT NOT NULL,
	ActionTypeId INT,
	SPName VARCHAR(200),
	Description NVARCHAR(4000),
	CONSTRAINT [PK_LogAction] PRIMARY KEY NONCLUSTERED 
	(
		ActionId ASC
	) ON LogData
) ON LogData
GO

CREATE CLUSTERED INDEX CIX_SPName ON dbo.LogAction (SPName) ON LogData
GO

CREATE TABLE dbo.LogType
(
	TypeId SMALLINT NOT NULL,
	TypeName NVARCHAR(50),
	Description NVARCHAR(50),
	CONSTRAINT [PK_LogType] PRIMARY KEY CLUSTERED 
	(
		TypeId ASC
	) ON LogData
) ON LogData
GO

CREATE TABLE [dbo].[Banners]
(
	BannerId INT IDENTITY(1,1) NOT NULL,
	FileName VARCHAR(100) NOT NULL,
	Category VARCHAR(50) NULL,
	Language VARCHAR(50) NULL,
	ImageType VARCHAR(50) NULL,
	Size VARCHAR(50) NULL,
	LastUpdate DATETIME NULL CONSTRAINT [DF_Affiliate_Banners_LastUpdate] DEFAULT (GETDATE()),
	Currency VARCHAR(5) NULL,
	CreatedDate DATETIME NULL,
	UpdatedBy INT NULL,
	Creator INT NULL,
	Message NVARCHAR(max) NULL,
	Type TINYINT NULL CONSTRAINT [DF_Banners_Type] DEFAULT ((0)),
	Version INT NULL CONSTRAINT [DF_Banners_Version] DEFAULT ((1)),
	AffType INT NULL,
	DeviceType TINYINT NULL CONSTRAINT [DF_Banners_DeviceType] DEFAULT ((0)),
	CONSTRAINT [PK_Banners] PRIMARY KEY CLUSTERED 
	(
		BannerId ASC
	) ON [SettingData]
) ON [SettingData] TEXTIMAGE_ON [SettingData]
GO

CREATE TABLE [dbo].[BannerTypes]
(
	Type VARCHAR(50) NULL,
	Value VARCHAR(50) NULL,
	DisplayOrder INT NULL
) ON [SettingData]
GO

CREATE TABLE [dbo].[ClickStatistics]
(
	ClickId BIGINT IDENTITY(1,1) NOT NULL,
	AffId INT NOT NULL,
	UpdatedTime DATETIME NOT NULL,
	IP VARCHAR(25) NOT NULL,
	Date SMALLDATETIME NOT NULL,
	Browser NVARCHAR(50) NOT NULL,
	URLReferrer NVARCHAR(300) NOT NULL,
	DomainReferrer NVARCHAR(300) NOT NULL,
	OS NVARCHAR(50),
	Device NVARCHAR(50),
	BrowserVersion NVARCHAR(16),
	BrowserResolution NVARCHAR(16),
	BrowserLanguage NVARCHAR(8),
	UserAgent NVARCHAR(256),
	Country NVARCHAR(256),
	LanguageCode VARCHAR(10),
	SportCode VARCHAR(50),
	RedirectURL NVARCHAR(256),
	Status TINYINT CONSTRAINT [DF_ClickStatistics_Status] DEFAULT ((0)),
	DeviceType TINYINT CONSTRAINT [DF_ClickStatistics_DeviceType] DEFAULT ((0)),
	CONSTRAINT [PK_ClickStatistics] PRIMARY KEY NONCLUSTERED
	(
		ClickId ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_AffId_Date ON [dbo].[ClickStatistics] (AffId, Date) ON [ReportData]
GO

CREATE TABLE [dbo].[ClickStatistics_bk]
(
	ClickId BIGINT NOT NULL,
	AffId INT NOT NULL,
	UpdatedTime DATETIME NOT NULL,
	IP VARCHAR(25) NOT NULL,
	Date SMALLDATETIME NOT NULL,
	Browser NVARCHAR(50) NOT NULL,
	URLReferrer NVARCHAR(300) NOT NULL,
	DomainReferrer NVARCHAR(300) NOT NULL,
	OS NVARCHAR(50),
	Device NVARCHAR(50),
	BrowserVersion NVARCHAR(16),
	BrowserResolution NVARCHAR(16),
	BrowserLanguage NVARCHAR(8),
	UserAgent NVARCHAR(256),
	Country NVARCHAR(256),
	LanguageCode VARCHAR(10),
	SportCode VARCHAR(50),
	RedirectURL NVARCHAR(256),
	Status TINYINT,
	DeviceType TINYINT,
	CONSTRAINT [PK_ClickStatistics_bk] PRIMARY KEY NONCLUSTERED
	(
		ClickId ASC
	)
) ON [ReportData]
GO

CREATE CLUSTERED INDEX CIX_Date_AffId ON [dbo].[ClickStatistics_bk] (Date, AffId) ON [ReportData]
GO

CREATE TABLE [dbo].[ClickStatisticsSum]
(
	AffId INT NOT NULL,
	DomainReferrer NVARCHAR(300) NOT NULL,
	Date SMALLDATETIME NOT NULL,
	LanguageCode VARCHAR(10) NOT NULL,
	SportCode VARCHAR(50) NOT NULL,
	DeviceType TINYINT NOT NULL,
	TotalClick INT,
	UniqueClick INT,
	TotalSignup INT,
	TotalDeposit INT,
	CONSTRAINT [PK_ClickStatisticsSum] PRIMARY KEY CLUSTERED 
	(
		Date ASC,
		AffId ASC,
		DomainReferrer ASC,
		SportCode ASC,
		LanguageCode ASC,
		DeviceType
	) ON [ReportData]
) ON [ReportData]
GO

CREATE TABLE [dbo].[LicenseeDomain](
	[DomainId] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL CONSTRAINT [DF_LicenseeDomain_CreateDate] DEFAULT (getdate()),
	[ModifyDate] [datetime] NULL CONSTRAINT [DF_LicenseeDomain_ModifyDate] DEFAULT (getdate()),
	[Creator] [int] NULL,
	[DeviceType] [tinyint] NULL CONSTRAINT [DF_LicenseeDomain_DeviceType] DEFAULT ((0)),
	[IsDeleted] [bit] NULL CONSTRAINT [DF_LicenseeDomain_IsDeleted] DEFAULT ((0)),
	[W3Prefix] [varchar](30) NULL,
	[IsSSL] [bit] NULL CONSTRAINT [DF_LicenseeDomain_IsSSL] DEFAULT ((0)),
	CONSTRAINT [PK_LicenseeDomain] PRIMARY KEY CLUSTERED 
	(
		[DomainId] ASC
	) ON [SettingData]
) ON [SettingData]
GO

CREATE TABLE [dbo].[AffDomain](
	[DomainId] [int] IDENTITY(1,1) NOT NULL,
	[DomainName] [nvarchar](50) NOT NULL,
	[CreateDate] [datetime] NULL CONSTRAINT [DF_AffDomain_CreateDate] DEFAULT (getdate()),
	[ModifyDate] [datetime] NULL CONSTRAINT [DF_AffDomain_ModifyDate] DEFAULT (getdate()),
	[Creator] [int] NULL,
	[IsDeleted] [bit] NULL DEFAULT ((0)),
	[IsSSL] [bit] NULL CONSTRAINT [DF_AffDomain_IsSSL] DEFAULT ((0)),
	CONSTRAINT [PK_AffDomain] PRIMARY KEY CLUSTERED 
	(
		[DomainId] ASC
	) ON [SettingData]
) ON [SettingData]

GO

CREATE TABLE [dbo].[DomainControl](
	[Id] [int] IDENTITY(1,1) NOT NULL,
	[AffDomainId] [int] NOT NULL,
	[LicenseeDomainId] [int] NOT NULL,
	[MarketId] [nvarchar](10) NOT NULL,
	[CreateDate] [datetime] NULL CONSTRAINT [DF_DomainControl_CreateDate] DEFAULT (getdate()),
	[ModifyDate] [datetime] NULL CONSTRAINT [DF_DomainControl_ModifyDate] DEFAULT (getdate()),
	[Creator] [int] NULL,
	[Status] [bit] NULL,
	[DeviceType] [tinyint] NULL CONSTRAINT [DF_DomainControl_DeviceType] DEFAULT ((0)),
	[IsDeleted] [bit] NULL CONSTRAINT [DF_DomainControl_IsDeleted] DEFAULT ((0)),
	CONSTRAINT [PK_DomainControl] PRIMARY KEY NONCLUSTERED 
	(
		[Id] ASC
	) ON [SettingData]
) ON [SettingData]
GO

CREATE CLUSTERED INDEX CIX_AffDomainId_LicenseeDomainId ON DomainControl (AffDomainId, LicenseeDomainId) ON [SettingData]
GO

CREATE TABLE [dbo].[AdminFavorite]
(
	[AdminId] [int] NOT NULL,
	[AffId] [int] NOT NULL,
 CONSTRAINT [PK_AdminFavorite] PRIMARY KEY CLUSTERED 
(
	[AdminId] ASC,
	[AffId] ASC
) ON [AffData]
) ON [AffData]

GO

CREATE TABLE [dbo].[AdminNotes](
	[NoteID] [int] IDENTITY(1,1) NOT NULL,
	[Note] [nvarchar](1000) NOT NULL,
	[UpdatedDate] [datetime] NOT NULL CONSTRAINT [DF_Affiliate_Note_UpdateDate]  DEFAULT (getdate()),
	[AffID] [int] NOT NULL,
	[UpdatedBy] [int] NOT NULL,
 CONSTRAINT [PK_AdminNotes] PRIMARY KEY CLUSTERED 
(
	[NoteID] ASC
) ON [AffData]
) ON [AffData]

GO

CREATE TABLE dbo.ExchangeOanda
(
	ExchangeDate SMALLDATETIME
	,ExchangeId INT
	,Code VARCHAR(5)
	,ActualRate FLOAT
	,VND FLOAT
	,EUR FLOAT
	,USD FLOAT
	,CNY FLOAT
	,MYR FLOAT
	,CONSTRAINT [PK_ExchangeOanda] PRIMARY KEY CLUSTERED
	(
		ExchangeDate ASC,
		ExchangeId ASC
	) ON SettingData
) ON SettingData
GO


CREATE TABLE [dbo].[IPv4Addresses]
(
	[From] [bigint] NOT NULL,
	[To] [bigint] NOT NULL,
	[Code2] [nchar](2) NOT NULL,
	[Code3] [nchar](3) NOT NULL,
	[Country] [nvarchar](64) NOT NULL
) ON [SettingData]
GO