/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20241108@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
*/
/*

	Migrate Affiliate Info Processing :
		+ AFF with status  'Disapproved' wont be migrated
		+ AFF have Duplicated Player_Username info  wont be migrated
		+ AFF with Asian Type will be migrated , exception 12BETAFF9966, 12BETAFF7782
		+ Only USD accounts (Country should be KH) established in the Cambodian market should be retained 
		+ PreferredPayment AFF's = Player without player_username info will be ignored
		+ PreferredPayment AFF's <> Player will be migrated to 'Player' PreferredPayment (if those AFF without player_username, it will be blank)
		+ Currency should be in below mapping list:
			Currency	V1	: V2
			MYR			2	: 2
			THB			4	: 4
			RMB			13	: 13
			IDR			15	: 15
			KRW			45	: 45
			VND			51	: 51
			INR			61	: 61
			BDT			97	: 74
			KHUSD		3	: 72
		+ ignor PreferredLanguage 'es-ES'
		+ Those Approved AFFs Group will be migrated to Default
	Step1: Migrate Aff Info
		+ Insert data  into table AffInfo
		+ Update random AffCode
		+ Migrate data Username_AutoIncrement
	Step2: Migrate AffDetail Info
*/

USE Affiliate_12B
GO
DECLARE @Currencys	 VARCHAR(200) = '2, 3, 4, 15, 61, 74, 72, 13, 51, 45'
	,@PrefixName NVARCHAR(50)	= '12BETAFF' 
	,@ApprovedBy INT			= 0
	,@DefaultCurrency INT		= 3
	,@CurrencyName NVARCHAR(50) = 'US$'
	,@CurrencyCode NVARCHAR(50) = 'USD'
	,@MonthDate SMALLDATETIME
	,@AffId	INT					= NULL
	,@MessageError VARCHAR(500)	= NULL
	,@ErrorCode INT				= 0

DECLARE @Market_Mapping TABLE(MarketId_V1 NVARCHAR(10), MarketId_V2 NVARCHAR(10))
DECLARE @ExchangeInfo TABLE(
	ExchangeID INT NOT NULL,
	CurrencyCode  NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL,
	TpExchangeID INT NOT NULL,
	CurrencyName NVARCHAR(50) COLLATE SQL_Latin1_General_CP1_CI_AS NOT NULL
)

SELECT @ApprovedBy = CustId 
FROM Affiliate_User WITH (NOLOCK) 
WHERE UserName  =  'sa';

INSERT INTO @Market_Mapping(MarketId_V1, MarketId_V2)
	SELECT MarketID, 
		CASE WHEN MarketID = 'hi-IN' THEN 'en-IN' 
				WHEN MarketID = 'hi' THEN 'hi-IN' 
		ELSE MarketID END MarketID_Mapping
	FROM Affiliate_12Bet.dbo.Market WITH(NOLOCK)

;WITH CTE_CurrencySupport AS(
	SELECT CONVERT(INT, t.value) as TpExchangeID
	FROM STRING_SPLIT(@Currencys,',')t
	
)

INSERT INTO @ExchangeInfo (ExchangeID, CurrencyCode, TpExchangeID, CurrencyName)
SELECT  ISNULL(tp.ExchangeId, e.ExchangeId) AS ExchangeId, e.Code, cs.TpExchangeID, e.currency 
FROM CTE_CurrencySupport cs
	LEFT JOIN dbo.TpExchange tp WITH (NOLOCK) ON cs.TpExchangeID = tp.TpExchangeID
	INNER JOIN bodb02.dbo.Exchange e WITH (NOLOCK) ON ISNULL(tp.ExchangeID, cs.TpExchangeID) = e.ExchangeId

--Get Info Exclude Aff
CREATE TABLE #AffExcluded (AffId INT NOT NULL)

;WITH CTE_DataDup AS(
	SELECT  Player_Username, COUNT(1) AS num
	FROM Affiliate_12Bet.dbo.AffDetail a WITH(NOLOCK)
		INNER JOIN Affiliate_12Bet.dbo.AffInfo w WITH(NOLOCK) ON a.affId = w.affId
	 GROUP BY Player_Username
	 HAVING COUNT(1)>1
 ),
 CTE_AffInfo AS(
	SELECT a.AffID, a.UserName,w.AffType, Player_IBCCustID, a.Player_Username, RegisteredDate, a.TargetCountryCode, a.PreferredLanguage, a.PreferredPayment, CASE WHEN w.Status = 'Approved' AND w.IsClosed = 1 THEN 'Closed' ELSE w.Status END AS Status
 	FROM Affiliate_12Bet.dbo.AffDetail a WITH (NOLOCK)
		INNER JOIN Affiliate_12Bet.dbo.AffInfo w WITH(NOLOCK) ON a.affId = w.affId
),
 CTE_AFFInvalid AS (
	 SELECT a.AffID,a.Status, a.Player_Username, NULL AS currency, 'Duplicated Player_Username' notes
	 FROM CTE_DataDup ct 
		 INNER JOIN CTE_AffInfo a WITH(NOLOCK) ON ct.Player_Username = a.Player_Username

	 UNION ALL
	 SELECT a.AffID,a.Status, a.Player_Username, NULL AS currency, 'LEN player_userame exceeds 30 characters' notes
	 FROM CTE_AffInfo a
	 WHERE LEN(a.Player_Username) > 30

	 UNION ALL
	 SELECT a.AffID,a.Status, a.Player_Username, NULL AS currency, 'Valid Player_UserName' notes
	 FROM CTE_AffInfo a
		LEFT JOIN DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust c WITH (NOLOCK) ON a.Player_Username = c.UserName
	 WHERE c.UserName IS NULL AND a.PreferredPayment = 'Player'

 ),
 CTE_AFFCurrencyNotRetain AS (
	 SELECT a.AffId, a.Status, a.Player_Username, currency
	 FROM CTE_AffInfo a
		INNER JOIN DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust d WITH (NOLOCK) ON a.Player_Username = d.username
	 WHERE NOT EXISTS ( 
			SELECT TOP 1 1 
			FROM @ExchangeInfo e
			WHERE d.currency = e.ExchangeID)
 ),
  CTE_AFFTypeNotRetain AS (
	 SELECT a.AffId
	 FROM CTE_AffInfo a
	 WHERE a.AffType <> 2
 ),
 CTE_AFFUSD AS (
	SELECT a.AffId, a.Status, a.Player_Username, d.currency
	FROM DBDEPOSIT2.Deposit_DB.dbo.v_Aff_DepCust d WITH (NOLOCK)
		INNER JOIN CTE_AffInfo a WITH(NOLOCK) ON a.Player_Username = d.username
	WHERE a.TargetCountryCode <> 'KH' AND d.Currency = 3
 ),
  CTE_NoSupportedMarket AS (
	SELECT a.AffId
	FROM CTE_AffInfo a
		LEFT JOIN @Market_Mapping m on m.MarketId_V1 = a.PreferredLanguage
	WHERE m.MarketId_V1 IS NULL
 )
 INSERT INTO #AffExcluded(AffId)
	SELECT AffID
	FROM CTE_AFFInvalid
	UNION 
	SELECT AffId
	FROM CTE_AFFCurrencyNotRetain
	UNION 
	SELECT AffId
	FROM CTE_AFFUSD
	UNION 
	SELECT AffId
	FROM CTE_NoSupportedMarket
	UNION 
	SELECT AffId
	FROM CTE_AFFTypeNotRetain

-- Specific AFF migrate
;WITH CTE_SpecificAFFMigrate AS(
SELECT b.AffID
	FROM (
			-- Specific AFF
			SELECT '12BETAFF130' AS Username UNION ALL
			SELECT '12BETAFF13902' AS Username UNION ALL
			SELECT '12BETAFF14617' AS Username UNION ALL
			SELECT '12BETAFF15775' AS Username UNION ALL
			SELECT '12BETAFF16050' AS Username UNION ALL
			SELECT '12BETAFF16096' AS Username UNION ALL
			SELECT '12BETAFF16097' AS Username UNION ALL
			SELECT '12BETAFF16105' AS Username UNION ALL
			SELECT '12BETAFF16311' AS Username UNION ALL
			SELECT '12BETAFF16313' AS Username UNION ALL
			SELECT '12BETAFF16314' AS Username UNION ALL
			SELECT '12BETAFF16325' AS Username UNION ALL
			SELECT '12BETAFF16326' AS Username UNION ALL
			SELECT '12BETAFF16341' AS Username UNION ALL
			SELECT '12BETAFF16342' AS Username UNION ALL
			SELECT '12BETAFF16343' AS Username UNION ALL
			SELECT '12BETAFF16344' AS Username UNION ALL
			SELECT '12BETAFF16225' AS Username UNION ALL
			SELECT '12BETAFF16214' AS Username UNION ALL
			SELECT '12BETAFF16205' AS Username UNION ALL
			SELECT '12BETAFF16204' AS Username UNION ALL
			SELECT '12BETAFF16186' AS Username UNION ALL
			SELECT '12BETAFF16000' AS Username UNION ALL
			SELECT '12BETAFF15932' AS Username UNION ALL
			SELECT '12BETAFF13506' AS Username UNION ALL
			SELECT '12BETAFF13065' AS Username UNION ALL
			SELECT '12BETAFF7782' AS Username UNION ALL
			-- Valid AFF
			SELECT '12BETAFF2233' AS Username UNION ALL
			SELECT '12BETAFF11440' AS Username UNION ALL
			SELECT '12BETAFF15154' AS Username UNION ALL
			SELECT '12BETAFF11937' AS Username UNION ALL
			SELECT '12BETAFF13316' AS Username UNION ALL
			SELECT '12BETAFF13229' AS Username UNION ALL
			SELECT '12BETAFF4097' AS Username UNION ALL
			SELECT '12BETAFF12405' AS Username UNION ALL
			SELECT '12BETAFF13065' AS Username UNION ALL
			SELECT '12BETAFF12853' AS Username UNION ALL
			SELECT '12BETAFF13969' AS Username UNION ALL
			SELECT '12BETAFF12231' AS Username UNION ALL
			SELECT '12BETAFF4028' AS Username UNION ALL
			SELECT '12BETAFF8379' AS Username UNION ALL
			SELECT '12BETAFF7021' AS Username UNION ALL
			SELECT '12BETAFF15925' AS Username UNION ALL
			SELECT '12BETAFF7754' AS Username UNION ALL
			SELECT '12BETAFF12875' AS Username UNION ALL
			SELECT '12BETAFF4802' AS Username UNION ALL
			SELECT '12BETAFF12557' AS Username UNION ALL
			SELECT '12BETAFF12452' AS Username UNION ALL
			SELECT '12BETAFF13533' AS Username UNION ALL
			SELECT '12BETAFF13064' AS Username UNION ALL
			SELECT '12BETAFF8135' AS Username UNION ALL
			SELECT '12BETAFF13002' AS Username UNION ALL
			SELECT '12BETAFF13377' AS Username UNION ALL
			SELECT '12BETAFF7998' AS Username UNION ALL
			SELECT '12BETAFF2656' AS Username UNION ALL
			SELECT '12BETAFF6846' AS Username UNION ALL
			SELECT '12BETAFF3695' AS Username UNION ALL
			SELECT '12BETAFF8596' AS Username UNION ALL
			SELECT '12BETAFF13113' AS Username UNION ALL
			SELECT '12BETAFF7202' AS Username UNION ALL
			SELECT '12BETAFF6475' AS Username UNION ALL
			SELECT '12BETAFF6579' AS Username UNION ALL
			SELECT '12BETAFF2978' AS Username UNION ALL
			SELECT '12BETAFF6746' AS Username UNION ALL
			SELECT '12BETAFF8701' AS Username UNION ALL
			SELECT '12BETAFF12138' AS Username UNION ALL
			SELECT '12BETAFF10325' AS Username UNION ALL
			SELECT '12BETAFF13080' AS Username UNION ALL
			SELECT '12BETAFF5491' AS Username UNION ALL
			SELECT '12BETAFF12635' AS Username UNION ALL
			SELECT '12BETAFF8114' AS Username UNION ALL
			SELECT '12BETAFF7777' AS Username UNION ALL
			SELECT '12BETAFF5226' AS Username UNION ALL
			SELECT '12BETAFF7430' AS Username UNION ALL
			SELECT '12BETAFF5285' AS Username UNION ALL
			SELECT '12BETAFF10410' AS Username UNION ALL
			SELECT '12BETAFF10539' AS Username UNION ALL
			SELECT '12BETAFF12277' AS Username UNION ALL
			SELECT '12BETAFF13008' AS Username UNION ALL
			SELECT '12BETAFF6817' AS Username UNION ALL
			SELECT '12BETAFF3522' AS Username UNION ALL
			SELECT '12BETAFF4344' AS Username UNION ALL
			SELECT '12BETAFF13514' AS Username UNION ALL
			SELECT '12BETAFF4185' AS Username UNION ALL
			SELECT '12BETAFF9068' AS Username UNION ALL
			SELECT '12BETAFF8476' AS Username UNION ALL
			SELECT '12BETAFF10820' AS Username UNION ALL
			SELECT '12BETAFF13098' AS Username UNION ALL
			SELECT '12BETAFF2805' AS Username UNION ALL
			SELECT '12BETAFF7916' AS Username UNION ALL
			SELECT '12BETAFF8063' AS Username UNION ALL
			SELECT '12BETAFF12032' AS Username UNION ALL
			SELECT '12BETAFF5115' AS Username UNION ALL
			SELECT '12BETAFF15476' AS Username UNION ALL
			SELECT '12BETAFF8267' AS Username UNION ALL
			SELECT '12BETAFF2935' AS Username UNION ALL
			SELECT '12BETAFF10474' AS Username UNION ALL
			SELECT '12BETAFF8112' AS Username UNION ALL
			SELECT '12BETAFF15760' AS Username UNION ALL
			SELECT '12BETAFF3134' AS Username UNION ALL
			SELECT '12BETAFF12714' AS Username UNION ALL
			SELECT '12BETAFF7298' AS Username UNION ALL
			SELECT '12BETAFF10838' AS Username UNION ALL
			SELECT '12BETAFF12948' AS Username UNION ALL
			SELECT '12BETAFF13428' AS Username UNION ALL
			SELECT '12BETAFF9232' AS Username UNION ALL
			SELECT '12BETAFF3574' AS Username UNION ALL
			SELECT '12BETAFF7699' AS Username UNION ALL
			SELECT '12BETAFF7159' AS Username UNION ALL
			SELECT '12BETAFF7555' AS Username UNION ALL
			SELECT '12BETAFF10825' AS Username UNION ALL
			SELECT '12BETAFF15075' AS Username UNION ALL
			SELECT '12BETAFF12591' AS Username UNION ALL
			SELECT '12BETAFF12631' AS Username UNION ALL
			SELECT '12BETAFF12868' AS Username UNION ALL
			SELECT '12BETAFF7832' AS Username UNION ALL
			SELECT '12BETAFF13369' AS Username UNION ALL
			SELECT '12BETAFF4518' AS Username UNION ALL
			SELECT '12BETAFF10995' AS Username UNION ALL
			SELECT '12BETAFF4913' AS Username UNION ALL
			SELECT '12BETAFF11762' AS Username UNION ALL
			SELECT '12BETAFF1958' AS Username UNION ALL
			SELECT '12BETAFF4652' AS Username UNION ALL
			SELECT '12BETAFF13348' AS Username UNION ALL
			SELECT '12BETAFF7216' AS Username UNION ALL
			SELECT '12BETAFF13321' AS Username UNION ALL
			SELECT '12BETAFF8629' AS Username UNION ALL
			SELECT '12BETAFF5709' AS Username UNION ALL
			SELECT '12BETAFF3348' AS Username UNION ALL
			SELECT '12BETAFF4170' AS Username UNION ALL
			SELECT '12BETAFF16127' AS Username UNION ALL
			SELECT '12BETAFF2054' AS Username UNION ALL
			SELECT '12BETAFF4388' AS Username UNION ALL
			SELECT '12BETAFF12822' AS Username UNION ALL
			SELECT '12BETAFF8576' AS Username UNION ALL
			SELECT '12BETAFF8508' AS Username UNION ALL
			SELECT '12BETAFF6159' AS Username UNION ALL
			SELECT '12BETAFF8503' AS Username UNION ALL
			SELECT '12BETAFF13169' AS Username UNION ALL
			SELECT '12BETAFF12186' AS Username UNION ALL
			SELECT '12BETAFF12531' AS Username UNION ALL
			SELECT '12BETAFF8491' AS Username UNION ALL
			SELECT '12BETAFF10499' AS Username UNION ALL
			SELECT '12BETAFF2968' AS Username UNION ALL
			SELECT '12BETAFF8355' AS Username UNION ALL
			SELECT '12BETAFF6928' AS Username UNION ALL
			SELECT '12BETAFF7593' AS Username UNION ALL
			SELECT '12BETAFF13272' AS Username UNION ALL
			SELECT '12BETAFF12865' AS Username UNION ALL
			SELECT '12BETAFF11546' AS Username UNION ALL
			SELECT '12BETAFF7931' AS Username UNION ALL
			SELECT '12BETAFF12862' AS Username UNION ALL
			SELECT '12BETAFF11843' AS Username UNION ALL
			SELECT '12BETAFF13480' AS Username UNION ALL
			SELECT '12BETAFF13264' AS Username UNION ALL
			SELECT '12BETAFF12854' AS Username UNION ALL
			SELECT '12BETAFF7179' AS Username UNION ALL
			SELECT '12BETAFF5744' AS Username UNION ALL
			SELECT '12BETAFF12747' AS Username UNION ALL
			SELECT '12BETAFF8921' AS Username UNION ALL
			SELECT '12BETAFF2973' AS Username UNION ALL
			SELECT '12BETAFF13295' AS Username UNION ALL
			SELECT '12BETAFF13474' AS Username UNION ALL
			SELECT '12BETAFF11042' AS Username UNION ALL
			SELECT '12BETAFF7736' AS Username UNION ALL
			SELECT '12BETAFF13126' AS Username UNION ALL
			SELECT '12BETAFF11863' AS Username UNION ALL
			SELECT '12BETAFF3261' AS Username UNION ALL
			SELECT '12BETAFF12938' AS Username UNION ALL
			SELECT '12BETAFF10830' AS Username UNION ALL
			SELECT '12BETAFF13407' AS Username UNION ALL
			SELECT '12BETAFF3775' AS Username UNION ALL
			-- euro/ media afftype
			SELECT '12BETAFF9966' AS Username UNION ALL
			SELECT '12BETAFF7782' AS Username UNION ALL
			-- exception handling Affs
			SELECT '12BETAFF13554' AS Username UNION ALL
			SELECT '12BETAFF12620' AS Username UNION ALL
			SELECT '12BETAFF14326' AS Username UNION ALL
			SELECT '12BETAFF14351' AS Username UNION ALL
			SELECT '12BETAFF226' AS Username UNION ALL
			SELECT '12BETAFF14327' AS Username UNION ALL
			SELECT '12BETAFF13409' AS Username UNION ALL
			SELECT '12BETAFF9089' AS Username UNION ALL
			SELECT '12BETAFF12716' AS Username 
	)AS t
		INNER JOIN Affiliate_12Bet.dbo.AffInfo b WITH (NOLOCK) ON b.UserName = t.UserName 
)
DELETE d
FROM #AffExcluded d
	INNER JOIN CTE_SpecificAFFMigrate c on c.AffID = d.AffId

CREATE TABLE #AffInfo_Output (AffId INT, UserName VARCHAR(30), GroupId INT)

BEGIN TRY
	SET IDENTITY_INSERT dbo.AffInfo ON;
	-- total ~ 8k rows
	INSERT INTO Affiliate_12B.dbo.AffInfo
		(AffId, UserName, UserName2, FirstName, LastName, GroupId, [Status], ApprovedDate, IsClosed, Currency, RegisteredDate, Email, [Password], AffType, IsPageEnabled, [Level], IsLocked, CasinoJoinedDate, ForceChangePass, SecretKey, CurrencyName, CurrencyCode, ParentAffId, AllParentAffId, IsSuspended, SuspendedDate,  ApprovedBy, DefaultCurrency, AffCode, IsRejected)
	OUTPUT INSERTED.AffId, INSERTED.UserName, INSERTED.GroupId INTO #AffInfo_Output (AffId, UserName, GroupId)
		SELECT w.AffId, 
			w.UserName, 
			NULL UserName2, 
			w.FirstName, 
			w.LastName, 
			CASE WHEN w.[Status] = 'Approved' THEN 1 ELSE 0 END AS GroupId, 
			w.[Status], 
			w.ApprovedDate, 
			0 AS IsClosed, 
			@DefaultCurrency AS Currency, 
			w.RegisteredDate, 
			w.Email, 
			w.[Password], 
			2 AS AffType, 
			NULL AS IsPageEnabled, 
			w.Level AS [Level], 
			0 AS IsLocked, 
			w.CasinoJoinedDate,
			w.ForceChangePass,
			SecretKey, 
			@CurrencyName AS CurrencyName, 
			@CurrencyCode AS CurrencyCode, 
			NULL ParentAffId,
			NULL AllParentAffId,
			0 AS IsSuspended,
			NULL AS SuspendedDate,
			CASE WHEN w.[Status] = 'Approved' THEN @ApprovedBy ELSE NULL END AS ApprovedBy, 
			@DefaultCurrency DefaultCurrency, 
			NULL AffCode, 
			CASE WHEN w.[Status] = 'Approved' AND w.IsClosed = 1 THEN 1 ELSE 0 END AS IsRejected
		FROM Affiliate_12Bet.dbo.AffInfo w WITH(NOLOCK) 
		WHERE NOT EXISTS (SELECT 1 FROM #AffExcluded a WHERE w.AffID = a.AffID)
			AND w.Status <> 'Disapproved'
			AND w.UserName LIKE '12BETAFF%'

	 SET IDENTITY_INSERT dbo.AffInfo OFF;
	
 -- Initial AffGroupHistory
 	SELECT @MonthDate = EOMONTH (SYSDATETIME())

	INSERT INTO dbo.AffGroupHistory (AffId, MonthDate, GroupId)
	SELECT AffId, @MonthDate AS MonthDate,  GroupId FROM #AffInfo_Output WHERE GroupId = 1

 -- Initial Username_AutoIncrement
	INSERT INTO dbo.Username_AutoIncrement (PrefixName, SubfixName)
	SELECT @PrefixName, (CONVERT(INT, RIGHT(UserName, LEN(UserName) - LEN(@PrefixName))))
	FROM #AffInfo_Output

	 -- Initial AffDetail
	 INSERT INTO Affiliate_12B.dbo.AffDetail
		(AffId, UserName, SiteURL, MoreSiteURLs, PreferredLanguage, Gender, Address, Postal, City, State, Country, Phone, MobilePhone, Fax, Question, Answer, PreferredPayment, Player_Username, Player_Currency, Neteller_AccountID, Moneybookers_Email, Wire_BankName, Wire_BankAddress, Wire_SwiftCode, Wire_AccountName, Wire_AccountNo, Cheque_FullName, Cheque_Address, Cheque_City, Cheque_State, Cheque_Postal, Cheque_Country, BonusCode, LastLoginDate, LastLoginIP, LoginCount, ValidCode, CodeExpiry, MailOption, NoSiteDesc, ContactApps, QuestionID, Player_CurrencyName, Player_CurrencyCode, Player_CustId, TransferLimit, DisabledTransfer)
		SELECT a.AffId, 
			a.UserName, 
			ISNULL(wd.SiteURL, '') AS SiteURL, 
			wd.MoreSiteURLs, 
			m.MarketId_V2 AS PreferredLanguage,
			Gender, 
			Address, 
			Postal, 
			City, 
			State, 
			Country, 
			Phone, 
			MobilePhone, 
			Fax, 
			Question, 
			Answer, 
			'Player' AS PreferredPayment,
			d.username AS Player_Username, 
			e.TpExchangeID AS Player_Currency, 
			Neteller_AccountID, 
			Moneybookers_Email, 
			Wire_BankName, 
			Wire_BankAddress, 
			Wire_SwiftCode, Wire_AccountName, Wire_AccountNo, Cheque_FullName, Cheque_Address, Cheque_City, Cheque_State, Cheque_Postal, Cheque_Country, BonusCode,NULL LastLoginDate, LastLoginIP, 
			0 AS LoginCount,
			NULL ValidCode, NULL CodeExpiry, 
			ISNULL(MailOption, 0) AS MailOption, 
			NoSiteDesc, ContactApps, 
			QuestionID, 
			e.CurrencyName AS  Player_CurrencyName,
			e.CurrencyCode AS Player_CurrencyCode, 
			d.CustId AS Player_CustId, 
			NULL TransferLimit, 
			1 AS DisabledTransfer
		FROM #AffInfo_Output a
			INNER JOIN Affiliate_12Bet.dbo.AffDetail wd WITH(NOLOCK) ON a.AffId = wd.AffId
			LEFT JOIN bodb_12B.dbo.Customer d WITH (NOLOCK) ON wd.Player_Username = d.username
			LEFT JOIN @ExchangeInfo e ON d.CurrencyId = e.TpExchangeID
			INNER JOIN @Market_Mapping m ON m.MarketId_V1 = wd.PreferredLanguage

 --- Generate random AffCode	
	;WITH CTE_DataGenerateAFFCode AS(
			SELECT ROW_NUMBER() OVER(ORDER BY NEWID()) + 10000  AS AffCode, AffId
			FROM #AffInfo_Output
		)
	UPDATE a SET AffCode = c.AffCode
	FROM Affiliate_12B.dbo.AffInfo a WITH(UPDLOCK, ROWLOCK)
		INNER JOIN CTE_DataGenerateAFFCode c ON a.AffId = c.AffId
	WHERE a.[Status] = 'Approved'
	;
	UPDATE a SET a.AffId = ai.AffId
	FROM Affiliate_12B.dbo.AffiliateCode a WITH(UPDLOCK, ROWLOCK)
		INNER JOIN Affiliate_12B.dbo.AffInfo ai WITH(NOLOCK)ON a.AffCode = ai.AffCode
	WHERE ai.AffCode IS NOT NULL

	PRINT 'Migrate Success'

END TRY
BEGIN CATCH
	SET IDENTITY_INSERT dbo.AffInfo OFF;
	TRUNCATE TABLE dbo.AffInfo
	TRUNCATE TABLE dbo.AffDetail
	TRUNCATE TABLE dbo.AffGroupHistory
	TRUNCATE TABLE Username_AutoIncrement
	UPDATE c SET AffId = NULL FROM AffiliateCode c WITH (UPDLOCK, ROWLOCK) WHERE AffId IS NOT NULL

	SELECT 'Migrate Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH
	DROP TABLE IF EXISTS #AffExcluded;
	DROP TABLE IF EXISTS #AffInfo_Output;

	--SELECT * from dbo.AffInfo 