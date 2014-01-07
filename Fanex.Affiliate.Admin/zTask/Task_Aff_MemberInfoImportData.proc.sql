ALTER PROCEDURE [dbo].[Task_Aff_MemberInfoImportData]	
	@AdminID int,	
	@XmlData XML,	
	@RegisteredDate smalldatetime,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(500) = '' OUTPUT
AS  
/*
	Task : Import member info FROM xml into table MemberInfo
	Author : Joseph@20130114
	DB: DB052.Affiliate_ZZun
	Original: [Aff_MemberInfoImportData]
	Revisions: 		
		20120122: apply currency converter
		Johnny@2013Mar27: Fix to update Clickstatistics table
		Peter@20131029 : Add more columns Email, FirstName, LastName, Phone, Address
		                 Calculate TotalMembers column in AffInfo table 
*/
BEGIN  
	SET NOCOUNT ON  

	DECLARE @InsMembers TABLE (UserName  VARCHAR(30), AffID INT)
	--Import new Data here
	DECLARE @TempTrans TABLE(
		UserName varchar(30),
		DepositCustID int,
		Btag varchar(100), 
		AffID int,
		ClickID bigint,
		RegisteredDate datetime, 
		Currency varchar(6),
		CountryID varchar(8),
		Email varchar(50),
		FirstName nvarchar(50),
		LastName nvarchar(50),
		Phone varchar(25),
		[Address] nvarchar(250))

	INSERT INTO @TempTrans(
		UserName,
		DepositCustID,
		Btag, 
		AffID,
		ClickID,
		RegisteredDate, 
		Currency,
		CountryID,
		Email,
		FirstName,
		LastName,
		Phone,
		[Address])
	 

	SELECT
		[Table].[Column].value('./@username', 'varchar(30)') as [UserName],
		[Table].[Column].value('./@playerid', 'int') as [DepositCustID],
		[Table].[Column].value('./@btag', 'varchar(100)') as [Btag],		
		[Table].[Column].value('./@affid', 'int') as [AffID],		
		[Table].[Column].value('./@clickid', 'int') as [ClickID],		
		@RegisteredDate as [RegisteredDate],
		[Table].[Column].value('./@currency', 'varchar(6)') as [Currency],
		[Table].[Column].value('./@country', 'varchar(8)') as [CountryID],
		[Table].[Column].value('./@email', 'varchar(50)') as [Email],
		[Table].[Column].value('./@firstname', 'nvarchar(50)') as [FirstName],
		[Table].[Column].value('./@lastname', 'nvarchar(50)') as [LastName],
		[Table].[Column].value('./@phone', 'varchar(25)') as [Phone],
		[Table].[Column].value('./@address', 'nvarchar(250)') as [Address]
	FROM @XmlData.nodes('/root/trans') as [Table]([Column])


	/*** Merging member info ***/
	;WITH TData AS
	(
		SELECT temp.*,cc.ExchangeID
		FROM @TempTrans AS temp
		INNER JOIN dbo.CurrencyConverter cc WITH(NOLOCK) ON temp.Currency = cc.PartnerCurrency AND cc.ApplicationID = 1
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON tmp.AffId = ai.AffId
	)
	MERGE INTO dbo.MemberInfo AS TARGET
	USING TData 
		ON TData.UserName = TARGET.UserName
	WHEN NOT MATCHED BY TARGET THEN
		INSERT(UserName
				, DepositCustID
				, Btag
				, AffID, ClickID, Currency
				, CountryID, RegisteredDate
				, [FirstName]
				, [LastName]
				, [Email]
				, [IsRemoved]
				, [Phone]
				, [Address])
		VALUES(TData.UserName
				, TData.DepositCustID
				, TData.Btag
				, TData.AffID, TData.ClickID, TData.ExchangeID
				, TData.CountryID, TData.RegisteredDate
				, TData.FirstName
				, TData.LastName
				, TData.Email
				, 0 --[IsRemoved]
				, TData.Phone
				, TData.[Address])
	WHEN MATCHED THEN
		UPDATE 
			SET m.DepositCustID = TData.DepositCustID,	
				m.Btag = TData.Btag,
				m.AffID = TData.AffID,
				m.ClickID = TData.ClickID,
				m.Currency = TData.ExchangeID, 
				m.RegisteredDate = TData.RegisteredDate,
				m.CountryID = TData.CountryID,
				m.Email=TData.Email,
				m.FirstName=TData.FirstName,
				m.LastName=TData.LastName,
				m.Phone=TData.Phone,
				m.[Address]=TData.[Address]
	OUTPUT Inserted.UserName
			, Inserted.AffID 
	INTO @InsMembers(UserName, AffID);

	-- Peter@20131029 : Calculate toal members for affiliate

	UPDATE ai 
		SET ai.TotalMembers=ISNULL(ai.TotalMembers, 0) + C.NUM
	FROM dbo.AffInfo ai WITH (ROWLOCK,UPDLOCK)
	INNER JOIN (
		SELECT ins.AffID, COUNT(DISTINCT ins.UserName) NUM 
		FROM @InsMembers ins
		GROUP BY ins.AffID
	) AS C ON ai.AffID=C.AffID


	--Update Click Statistics
	DECLARE @MinClickID bigint, @MinClickID_Statistics bigint

	SELECT @MinClickID = min(ClickId)
	FROM @TempTrans

	SELECT @MinClickID_Statistics = min(ClickId)
	FROM dbo.ClickStatistics WITH (NOLOCK)

	IF @MinClickID < @MinClickID_Statistics
	BEGIN
		--Temp table to insert click value to update to clickstatisticsSum table
		DECLARE @TmpClickDetail TABLE ([date] SMALLDATETIME)

		INSERT INTO @TmpClickDetail(date)
		SELECT DISTINCT c.[date]
		FROM @TempTrans as t
		INNER JOIN dbo.ClickStatistics_bk as c on t.[clickId] = c.ClickID
		WHERE c.ClickId < @MinClickID_Statistics
		
		DELETE dbo.ClickStatisticsSum
		WHERE [Date] in (SELECT [DATE] FROM @TmpClickDetail)

		--Summary for Daily by Domain and Date
		INSERT INTO dbo.ClickStatisticsSum(AffID, [DomainReferrer], [Date], [SportCode], [LanguageCode], TotalClick, UniqueClick, TotalSignup, TotalDeposit)
		SELECT  c.AffID,
				DomainReferrer,
				c.[Date] as [Date],
				SportCode,
				LanguageCode,
				SUM(ClickCount) as TotalClick,
				COUNT(distinct IP) as UniqueClick,
				SUM(ISNULL(Signups, 0)) as Signups,
				SUM(ISNULL(FDM, 0)) as  FDM 
		FROM dbo.ClickStatistics_bk c with (nolock)
		INNER JOIN @TmpClickDetail t on c.[Date] = t.[Date]
		LEFT JOIN 
			(SELECT ClickId, 
				SUM(CASE WHEN m.RegisteredDate is not null THEN 1 ELSE 0 END) as Signups,
				SUM(CASE WHEN m.CreatedDate is not null THEN 1 ELSE 0 END) as  FDM 
			FROM dbo.MemberInfo m WITH (NOLOCK) 			
			WHERE m.ClickId > @MinClickID AND m.ClickId < @MinClickID_Statistics
			GROUP BY m.ClickId
		) as m on c.ClickId = m.ClickId
		WHERE c.ClickId >= @MinClickID AND c.ClickId < @MinClickID_Statistics
		GROUP BY c.AffID, DomainReferrer, c.[Date], SportCode, LanguageCode
	END
END  