/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250311@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #219664]
		1. Migrate data table AffInfo, AffDetail Specific AFFs: 25 AFF
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

--Get Info  Aff
CREATE TABLE #AffMigrate (AffId INT NOT NULL, Player_UserName VARCHAR(30))
INSERT INTO #AffMigrate(AffId, Player_UserName)
	SELECT b.AffID, ISNULL(t.Player_UserName, bi.Player_Username) AS Player_UserName
	FROM (
			SELECT '12BETAFF5624' as Username, '12BETAFF5624' Player_Username UNION ALL
			SELECT '12BETAFF4234' as Username, '12BETAFF4234' Player_Username UNION ALL
			SELECT '12BETAFF3007' as Username, '12BETAFF3007' Player_Username UNION ALL
			SELECT '12BETAFF2970' as Username, '12BETAFF2970' Player_Username UNION ALL
			SELECT '12BETAFF1430' as Username, '12BETAFF1430' Player_Username UNION ALL
			SELECT '12BETAFF1984' as Username, '12BETAFF1984' Player_Username UNION ALL
			SELECT '12BETAFF1835' as Username, '12BETAFF1835' Player_Username UNION ALL
			SELECT '12BETAFF001' as Username, '12BETAFF001' Player_Username UNION ALL
			SELECT '12BETAFF13763' as Username, 'betinasia' Player_Username UNION ALL
			SELECT '12BETAFF286' as Username, 'Eurotip1' Player_Username UNION ALL
			SELECT '12BETAFF3310' as Username, 'baohan58' Player_Username UNION ALL
			SELECT '12BETAFF9143' as Username, 'maganda7410' Player_Username UNION ALL
			SELECT '12BETAFF9167' as Username, 'redsea07' Player_Username UNION ALL
			SELECT '12BETAFF4481' as Username, 'henryhuynh' Player_Username UNION ALL
			SELECT '12BETAFF2222' as Username, 'nguthaphu' Player_Username UNION ALL
			SELECT '12BETAFF2687' as Username, 'zantalesblog' Player_Username UNION ALL
			SELECT '12BETAFF3229' as Username, '12BETAFF3229' Player_Username UNION ALL
			SELECT '12BETAFF9052' as Username, 'kim9052' Player_Username UNION ALL
			SELECT '12BETAFF14398' as Username, 'tigerking1309' Player_Username UNION ALL
			SELECT '12BETAFF13678' as Username, 'davit' Player_Username UNION ALL
			SELECT '12BETAFF4333' as Username, 'Vach86' Player_Username UNION ALL
			SELECT '12BETAFF2608' as Username, 'chapa81' Player_Username UNION ALL
			SELECT '12BETAFF7600' as Username, 'catalinjohn' Player_Username UNION ALL
			SELECT '12BETAFF1436' as Username, 'wettportal' Player_Username UNION ALL
			SELECT '12BETAFF15797' as Username, 'top100book' Player_Username
	)AS t
		INNER JOIN Affiliate_12BET.dbo.AffInfo b WITH (NOLOCK) ON b.UserName = t.UserName 
		INNER JOIN Affiliate_12BET.dbo.AffDetail bi WITH (NOLOCK) ON b.AffId = bi.AffId 
		LEFT JOIN dbo.AffInfo a WITH(NOLOCK) ON a.UserName = t.UserName
	WHERE a.UserName IS NULL

	CREATE TABLE #AffInfo_Output (AffId INT, UserName VARCHAR(30), GroupId INT)

BEGIN TRY
	PRINT 'Inserting AffInfo'
	SET IDENTITY_INSERT dbo.AffInfo ON;
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
			INNER JOIN #AffMigrate a ON w.AffID= a.AffId

	 SET IDENTITY_INSERT dbo.AffInfo OFF;

 -- Initial AffGroupHistory
 	SELECT @MonthDate = EOMONTH (SYSDATETIME())
	PRINT 'Inserting AffGroupHistory'
	INSERT INTO dbo.AffGroupHistory (AffId, MonthDate, GroupId)
	SELECT AffId, @MonthDate AS MonthDate,  GroupId FROM #AffInfo_Output WHERE GroupId = 1

 -- Initial Username_AutoIncrement
	PRINT 'Inserting Username_AutoIncrement'
	INSERT INTO dbo.Username_AutoIncrement (PrefixName, SubfixName)
	SELECT @PrefixName, (CONVERT(INT, RIGHT(UserName, LEN(UserName) - LEN(@PrefixName))))
	FROM #AffInfo_Output

	 -- Initial AffDetail
	 PRINT 'Inserting AffDetail'
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
			INNER JOIN #AffMigrate w ON w.AffID= a.AffId
			LEFT JOIN bodb_12B.dbo.Customer d WITH (NOLOCK) ON w.Player_Username = d.username
			LEFT JOIN @ExchangeInfo e ON d.CurrencyId = e.TpExchangeID
			INNER JOIN @Market_Mapping m ON m.MarketId_V1 = wd.PreferredLanguage
	
 --- Generate random AffCode
	DECLARE @Max_AffCode INT = 0
	SELECT @Max_AffCode = MAX(CONVERT(INT, AffCode))
	FROM dbo.AffInfo WITH(NOLOCK)
	WHERE AffCode IS NOT NULL

	PRINT 'Generating AffCode'
	;WITH CTE_DataGenerateAFFCode AS(
			SELECT ROW_NUMBER() OVER(ORDER BY NEWID()) + @Max_AffCode  AS AffCode, AffId
			FROM #AffInfo_Output
		)
	UPDATE a SET AffCode = c.AffCode
	FROM Affiliate_12B.dbo.AffInfo a WITH(UPDLOCK, ROWLOCK)
		INNER JOIN #AffInfo_Output co WITH (NOLOCK) ON a.AffId = co.AffId
		INNER JOIN CTE_DataGenerateAFFCode c ON a.AffId = c.AffId
	WHERE a.[Status] = 'Approved' 
	;
	PRINT 'Updateing AffiliateCode'
	UPDATE a SET a.AffId = ai.AffId
	FROM Affiliate_12B.dbo.AffiliateCode a WITH(UPDLOCK, ROWLOCK)	
		INNER JOIN Affiliate_12B.dbo.AffInfo ai WITH(NOLOCK)ON a.AffCode = ai.AffCode
		INNER JOIN #AffInfo_Output co WITH (NOLOCK) ON ai.AffId = co.AffId
	WHERE ai.AffCode IS NOT NULL

	PRINT 'Migrate Success'

END TRY
BEGIN CATCH

	SET IDENTITY_INSERT dbo.AffInfo OFF;

	DELETE c 
	FROM dbo.AffInfo c WITH(ROWLOCK)
		INNER JOIN #AffInfo_Output a ON a.AffId = c.AffId

	DELETE c 
	FROM dbo.AffDetail c WITH(ROWLOCK)
		INNER JOIN #AffInfo_Output a ON a.AffId = c.AffId

	DELETE c  
	FROM dbo.AffGroupHistory c
		INNER JOIN #AffInfo_Output a ON a.AffId = c.AffId

	DELETE c 
	FROM Username_AutoIncrement c
		INNER join #AffInfo_Output a ON (CONVERT(INT, RIGHT(a.UserName, LEN(a.UserName) - LEN('12BETAFF')))) = c.SubfixName

	UPDATE c SET AffId = NULL
	FROM AffiliateCode c WITH (UPDLOCK, ROWLOCK) 
		INNER JOIN #AffInfo_Output a ON a.AffId = c.AffId
	WHERE c.AffId IS NOT NULL

	SELECT 'Migrate Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH

	DROP TABLE IF EXISTS #AffMigrate;
	DROP TABLE IF EXISTS #AffInfo_Output;

