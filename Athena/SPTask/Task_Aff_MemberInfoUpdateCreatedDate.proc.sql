/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_MemberInfoUpdateCreatedDate] 
	@XmlData XML
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg NVARCHAR(500) = '' OUTPUT
AS
/*
	Task : Update created date for users deposited
	Author : Johnny@20130328
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberInfoImportData]
	Revisions: 		
		Johnny@2013Mar27: Fix to update Clickstatistics, Clickstatistics_bk and ClickstatisticsSum table
		- 20250415@Sophia: Build version UAT for testing new API [Redmine #223271]
*/
--Import new Data here 
DECLARE @TmpClick TABLE (ClickId BIGINT)
DECLARE @TempTrans TABLE (
	UserName VARCHAR(30)
	,IBCUserName VARCHAR(50)
	,DATE DATETIME
	,Email VARCHAR(50)
	,FirstName NVARCHAR(50)
	,LastName NVARCHAR(50)
	,Phone VARCHAR(20)
	,Address NVARCHAR(255)
	)

INSERT INTO @TempTrans (
	UserName
	,IBCUserName
	,DATE
	,Email
	,FirstName
	,LastName
	,Phone
	,Address
	)
SELECT [Table].[Column].value('./@username', 'varchar(30)') AS [UserName]
	,[Table].[Column].value('./@ibcusername', 'varchar(50)') AS [IBCUserName]
	,[Table].[Column].value('./@date', 'datetime') AS [Date]
	,[Table].[Column].value('./@email', 'varchar(50)') AS [Email]
	,[Table].[Column].value('./@firstname', 'nvarchar(50)') AS [FirstName]
	,[Table].[Column].value('./@lastname', 'nvarchar(50)') AS [LastName]
	,[Table].[Column].value('./@phone', 'varchar(20)') AS [Phone]
	,[Table].[Column].value('./@address', 'nvarchar(255)') AS [Address]
FROM @XmlData.nodes('/root/trans') AS [Table]([Column])

UPDATE m
SET m.CreatedDate = TEMP.DATE
	,m.IBCUsername = TEMP.IBCUserName
	,m.Email = TEMP.Email
	,m.FirstName = TEMP.FirstName
	,m.LastName = TEMP.LastName
	,m.Phone = TEMP.Phone
	,m.Address = TEMP.Address
	,m.AffAffectedDate = ISNULL(TEMP.DATE, m.RegisteredDate)
OUTPUT Inserted.ClickId
INTO @TmpClick
FROM MemberInfo_UAT AS m
	INNER JOIN @TempTrans AS TEMP
	ON m.UserName = TEMP.UserName;

--Update Click Statistics
DECLARE @MinClickID BIGINT
	,@MinClickID_Statistics BIGINT

SELECT @MinClickID = min(ClickId)
FROM @TmpClick

SELECT @MinClickID_Statistics = min(ClickId)
FROM ClickStatistics_UAT NOLOCK

IF @MinClickID < @MinClickID_Statistics
	RETURN

BEGIN
	--Temp table to insert click value to update to ClickStatisticsSum table
	DECLARE @TmpClickDetail TABLE ([date] SMALLDATETIME)

	INSERT INTO @TmpClickDetail (DATE)
	SELECT DISTINCT c.DATE
	FROM @TmpClick AS t
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
