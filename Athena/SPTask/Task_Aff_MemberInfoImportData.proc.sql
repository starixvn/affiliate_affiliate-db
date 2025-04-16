/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfoImportData] 
	@AdminID INT
	,@XmlData XML
	,@RegisteredDate SMALLDATETIME
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
	Task : Import member info from xml into table MemberInfo
	Author : Joseph@20130114
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberInfoImportData]
	Revisions: 		
		20120122: apply currency converter
		Johnny@2013Mar27: Fix to update Clickstatistics table
		Peter@20131029 : Add more columns Email, FirstName, LastName, Phone, Address
		                 Calculate TotalMembers column in AffInfo table 
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @TmpTable TABLE (UserName VARCHAR(30))
	--Import new Data here
	DECLARE @TempTrans TABLE (
		UserName VARCHAR(30)
		,DepositCustID INT
		,Btag VARCHAR(100)
		,AffID INT
		,ClickID BIGINT
		,RegisteredDate DATETIME
		,Currency VARCHAR(6)
		,CountryID VARCHAR(8)
		,Email VARCHAR(50)
		,FirstName NVARCHAR(50)
		,LastName NVARCHAR(50)
		,Phone VARCHAR(20)
		,Address NVARCHAR(255)
		)

	INSERT INTO @TempTrans (
		UserName
		,DepositCustID
		,Btag
		,AffID
		,ClickID
		,RegisteredDate
		,Currency
		,CountryID
		,Email
		,FirstName
		,LastName
		,Phone
		,Address
		)
	SELECT [Table].[Column].value('./@username', 'varchar(30)') AS [UserName]
		,[Table].[Column].value('./@playerid', 'int') AS [DepositCustID]
		,[Table].[Column].value('./@btag', 'varchar(100)') AS [Btag]
		,[Table].[Column].value('./@affid', 'int') AS [AffID]
		,[Table].[Column].value('./@clickid', 'int') AS [ClickID]
		,@RegisteredDate AS [RegisteredDate]
		,[Table].[Column].value('./@currency', 'varchar(6)') AS [Currency]
		,[Table].[Column].value('./@country', 'varchar(8)') AS [CountryID]
		,[Table].[Column].value('./@email', 'varchar(50)') AS [Email]
		,[Table].[Column].value('./@firstname', 'nvarchar(50)') AS [FirstName]
		,[Table].[Column].value('./@lastname', 'nvarchar(50)') AS [LastName]
		,[Table].[Column].value('./@phone', 'varchar(20)') AS [Phone]
		,[Table].[Column].value('./@address', 'nvarchar(255)') AS [Address]
	FROM @XmlData.nodes('/root/trans') AS [Table]([Column])

	--Update info if this user exists in MemberInfo table
	UPDATE m
	SET m.DepositCustID = TEMP.DepositCustID
		,m.Btag = TEMP.Btag
		,
		--m.AffID = temp.AffID,
		m.ClickID = TEMP.ClickID
		,m.Currency = cc.ExchangeID
		,m.RegisteredDate = TEMP.RegisteredDate
		,m.CountryID = TEMP.CountryID
		,m.Email = TEMP.Email
		,m.FirstName = TEMP.FirstName
		,m.LastName = TEMP.LastName
		,m.Phone = TEMP.Phone
		,m.Address = TEMP.Address
	OUTPUT Inserted.UserName
	INTO @TmpTable
	FROM MemberInfo_UAT AS m
		INNER JOIN @TempTrans AS TEMP
		ON m.UserName = TEMP.UserName
		INNER JOIN CurrencyConverter_UAT cc
		ON TEMP.Currency = cc.PartnerCurrency
			AND cc.ApplicationID = 1
		INNER JOIN AffInfo_UAT AS ai WITH (NOLOCK)
		ON m.AffId = ai.AffId

	--Insert new members into MemberInfo table
	INSERT INTO MemberInfo_UAT (
		UserName
		,DepositCustID
		,Btag
		,AffID
		,ClickID
		,Currency
		,CountryID
		,RegisteredDate
		,[FirstName]
		,[LastName]
		,[Email]
		,[IsRemoved]
		,[Phone]
		,[Address]
		,[AffAffectedDate]
		)
	SELECT TEMP.UserName
		,TEMP.DepositCustID
		,TEMP.Btag
		,TEMP.AffID
		,TEMP.ClickID
		,cc.ExchangeID
		,CountryID
		,TEMP.RegisteredDate
		,TEMP.FirstName
		,TEMP.LastName
		,TEMP.Email
		,0 AS IsRemoved
		,TEMP.Phone
		,TEMP.Address
		,TEMP.RegisteredDate
	FROM @TempTrans TEMP
		INNER JOIN CurrencyConverter_UAT cc
		ON TEMP.Currency = cc.PartnerCurrency
			AND cc.ApplicationID = 1
		INNER JOIN AffInfo_UAT AS ai WITH (NOLOCK)
		ON TEMP.AffId = ai.AffId
	WHERE TEMP.UserName NOT IN (
			SELECT UserName
			FROM @TmpTable
			);

	--Calculate total members for affiliate
	UPDATE ai
	SET ai.TotalMembers = dbo.Aff_CountMember(t.AffID)
	FROM AffInfo_UAT ai WITH (ROWLOCK, UPDLOCK)
		INNER JOIN @TempTrans t
		ON t.AffID = ai.AffID

	--Update Click Statistics
	DECLARE @MinClickID BIGINT
		,@MinClickID_Statistics BIGINT

	SELECT @MinClickID = min(ClickId)
	FROM @TempTrans

	SELECT @MinClickID_Statistics = min(ClickId)
	FROM ClickStatistics_UAT(NOLOCK)

	IF @MinClickID < @MinClickID_Statistics
		RETURN

	BEGIN
		--Temp table to insert click value to update to ClickStatisticsSum table
		DECLARE @TmpClickDetail TABLE ([date] SMALLDATETIME)

		INSERT INTO @TmpClickDetail (DATE)
		SELECT DISTINCT c.DATE
		FROM @TempTrans AS t
			INNER JOIN ClickStatistics_bk AS c
			ON t.[clickId] = c.ClickID
		WHERE c.ClickId < @MinClickID_Statistics

		DELETE ClickStatisticsSum
		WHERE DATE IN (
				SELECT [DATE]
				FROM @TmpClickDetail
				)

		--Summary for Daily by Domain and Date
		INSERT INTO ClickStatisticsSum (
			AffID
			,[DomainReferrer]
			,[Date]
			,[SportCode]
			,[LanguageCode]
			,TotalClick
			,UniqueClick
			,TotalSignup
			,TotalDeposit
			)
		SELECT c.AffID
			,DomainReferrer
			,c.[Date] AS [Date]
			,SportCode
			,LanguageCode
			,sum(ClickCount) AS TotalClick
			,count(DISTINCT IP) AS UniqueClick
			,SUM(isnull(Signups, 0)) AS Signups
			,SUM(isnull(FDM, 0)) AS FDM
		FROM ClickStatistics_bk c WITH (NOLOCK)
			INNER JOIN @TmpClickDetail t
			ON c.DATE = t.DATE
			LEFT JOIN (
			SELECT ClickId
				,SUM(CASE 
						WHEN m.RegisteredDate IS NOT NULL THEN 1
						ELSE 0
						END) AS Signups
				,SUM(CASE 
						WHEN m.CreatedDate IS NOT NULL THEN 1
						ELSE 0
						END) AS FDM
			FROM MemberInfo_UAT m WITH (NOLOCK)
			GROUP BY ClickId
			) AS m
			ON c.ClickId = m.ClickId
		GROUP BY c.AffID
			,DomainReferrer
			,c.[Date]
			,SportCode
			,LanguageCode
	END
END
