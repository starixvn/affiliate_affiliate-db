USE [Affiliate_12BET];
GO

IF (NOT EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'SeqAffInfo')
	OR NOT EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'EUAffiliates') 
	) 
BEGIN
	PRINT 'Not found dependencies'
	RETURN;
END


DECLARE @AffPrefix VARCHAR(20) = '12BetAff';

SELECT seq.*
	, @AffPrefix + CASE 
				WHEN seq.SeqID < 999  THEN '00' + CAST(seq.SeqID AS VARCHAR(5)) 
				ELSE
					CAST(seq.SeqID AS VARCHAR(10)) 
				END UserName
INTO #tmpAffInfo
FROM dbo.SeqAffInfo seq

-- SET IDENTITY_INSERT to ON.
SET IDENTITY_INSERT dbo.AffInfo ON;

--Insert into [AffInfo]
--INSERT INTO [dbo].[AffInfo]
--           ([AffID]
--			 ,[UserName]
--           ,[UserName2]
--           ,[FirstName]
--           ,[LastName]
--           ,[GroupID]
--           ,[Status]
--           ,[ApprovedDate]
--           ,[IsClosed]
--           ,[Currency]
--           ,[RegisteredDate]
--           ,[Email]
--           ,[Password]
--           ,[AffType]
--           ,[IsPageEnabled]
--           ,[Level]
--           ,[IsLocked]
--           ,[CasinoJoinedDate]
--           ,[EUAffID]
--           ,[ForceChangePass])
SELECT seq.AffID
	,CAST(UPPER(seq.UserName) AS NVARCHAR(30)) AS UserName
    ,CAST(eu.UserName AS NVARCHAR(30)) AS UserName2
    ,CAST(eu.FirstName AS nvarchar(50)) AS FirstName
    ,CAST(eu.LastName AS nvarchar(50)) AS LastName
    ,CASE eu.PreferedPayment 
		WHEN 'NoPayment' THEN 121 --EU_NoComm
		ELSE 120 --EUComm_Default
		END GroupID
    ,CAST('approved' AS varchar(30)) AS [Status]
    ,CAST(GETDATE() AS smalldatetime) AS ApprovedDate
    ,0 AS IsClosed
    ,3 AS Currency --USD currency
    ,CAST(GETDATE() AS smalldatetime) AS RegisteredDate
    ,CAST(eu.EmailAddress AS nvarchar(50)) AS [Email]
    ,CAST(PwdHash AS varchar(40)) AS [Password]
    ,1 AS AffType --European
    ,0 AS IsPageEnabled
    ,0 AS [Level]
    ,0 AS IsLocked
    ,NULL AS CasinoJoinedDate
    ,eu.EUAffID
    ,1 AS ForceChangePass
FROM #tmpAffInfo seq 
INNER JOIN dbo.EUAffiliates eu ON seq.EUAffID = eu.EUAffID

--Insert into [AffDetail]
--INSERT INTO [dbo].[AffDetail]
--           ([AffID]
--           ,[UserName]
--           ,[SiteURL]
--           ,[MoreSiteURLs]
--           ,[PreferredLanguage]
--           ,[Gender]
--           ,[Address]
--           ,[Postal]
--           ,[City]
--           ,[State]
--           ,[Country]
--           ,[Phone]
--           ,[MobilePhone]
--           ,[Fax]
--           ,[Question]
--           ,[Answer]
--           ,[PreferredPayment]
--           ,[Player_IBCCustID]
--           ,[Player_Username]
--           ,[Neteller_AccountID]
--           ,[Moneybookers_Email]
--           ,[Wire_BankName]
--           ,[Wire_BankAddress]
--           ,[Wire_SwiftCode]
--           ,[Wire_AccountName]
--           ,[Wire_AccountNo]
--           ,[Cheque_FullName]
--           ,[Cheque_Address]
--           ,[Cheque_City]
--           ,[Cheque_State]
--           ,[Cheque_Postal]
--           ,[Cheque_Country]
--           ,[BonusCode]
--           ,[LastLoginDate]
--           ,[LastLoginIP]
--           ,[LoginCount]
--           ,[ValidCode]
--           ,[CodeExpiry]
--           ,[MailOption]
--           ,[NoSiteDesc])
 SELECT seq.AffID
	,CAST(UPPER(seq.UserName) AS NVARCHAR(30)) AS UserName
    ,eu.WebsiteURL			-- varchar(100)
    ,eu.AdditionalURL		-- <MoreSiteURLs, varchar(1000),>
    ,eu.PrefferedLanguage	--<PreferredLanguage, varchar(11),>
    ,eu.Gender				--<Gender, bit,>
    ,eu.[Address]			--<Address, nvarchar(80),>
    ,eu.Postcode			-- <Postal, nvarchar(50),>
    ,eu.City				--<City, nvarchar(50),>
    ,eu.[State]				--<State, nvarchar(50),>
    ,eu.Country				--<Country, nvarchar(50),>
    ,NULL AS Phone			-- <Phone, varchar(50),>
    ,NULL AS MobilePhone	--<MobilePhone, varchar(50),>
    ,NULL AS Fax			--<Fax, varchar(50),>
    ,eu.SecurityQuestion	--<Question, nvarchar(300),>
    ,eu.YourAnswer			--<Answer, nvarchar(300),>
    ,eu.PreferedPayment		--<PreferredPayment, varchar(20),>
	,CASE eu.PreferedPayment --Wire|Player|Neteller|Moneybookers
		WHEN 'Player' THEN eu.Player_IBCCustID
		ELSE '' 
		END Player_IBCCustID	--<Player_IBCCustID, int,>
    ,CASE eu.PreferedPayment	--Wire|Player|Neteller|Moneybookers
		WHEN 'Player' THEN eu.PlayerAccount
		ELSE NULL 
		END Player_Username		--<Player_Username, varchar(30),>
    ,CASE eu.PreferedPayment
		WHEN 'Neteller' THEN eu.PlayerAccount
		ELSE NULL 
		END Neteller_AccountID		--<Neteller_AccountID, varchar(50),>
    ,CASE eu.PreferedPayment
		WHEN 'Moneybookers' THEN eu.PlayerAccount
		ELSE NULL 
		END Moneybookers_Email		--<Moneybookers_Email, nvarchar(50),>
    ,CASE eu.PreferedPayment
		WHEN 'Wire' THEN eu.PlayerAccount
		ELSE NULL 
		END Wire_BankName		--<Wire_BankName, nvarchar(100),>
    ,NULL AS Wire_BankAddress	--<Wire_BankAddress, nvarchar(200),>
    ,NULL AS Wire_SwiftCode		--<Wire_SwiftCode, nvarchar(50),>
    ,NULL AS Wire_AccountName	--<Wire_AccountName, nvarchar(100),>
    ,NULL AS Wire_AccountNo		--<Wire_AccountNo, varchar(50),>
    ,NULL AS Cheque_FullName	--<Cheque_FullName, nvarchar(200),>
    ,NULL AS Cheque_Address		--<Cheque_Address, nvarchar(200),>
    ,NULL AS Cheque_City		--<Cheque_City, nvarchar(50),>
    ,NULL AS Cheque_State		--<Cheque_State, nvarchar(50),>
    ,NULL AS Cheque_Postal		--<Cheque_Postal, nvarchar(50),>
    ,NULL AS Cheque_Country		--<Cheque_Country, nvarchar(50),>
    ,NULL AS BonusCode			--<BonusCode, varchar(20),>
    ,NULL AS LastLoginDate		--<LastLoginDate, smalldatetime,>
    ,NULL AS LastLoginIP		--<LastLoginIP, nvarchar(20),>
    ,NULL AS LoginCount			--<LoginCount, tinyint,>
    ,NULL AS ValidCode			--<ValidCode, nvarchar(11),>
    ,NULL AS CodeExpiry			--<CodeExpiry, datetime,>
    ,NULL AS MailOption			--<MailOption, bit,>
    ,NULL AS NoSiteDesc			--<NoSiteDesc, nvarchar(1000),>
FROM #tmpAffInfo seq 
INNER JOIN dbo.EUAffiliates eu ON seq.EUAffID = eu.EUAffID

SET IDENTITY_INSERT dbo.AffInfo OFF;

DROP TABLE #tmpAffInfo;           
GO
