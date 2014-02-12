USE [Affiliate_12BET];
GO

IF (EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'SeqClickStats'
		)
	) DROP TABLE dbo.SeqClickStats;

CREATE TABLE dbo.SeqClickStats (
	SeqID INT
	,DepositCustID INT
	,SeqDate DATETIME
);

--initial SeqID
DECLARE @InitSeqID INT;

SELECT @InitSeqID = MAX([ClickID])
FROM [dbo].[ClickStatistics1] WITH(NOLOCK)

SET @InitSeqID = ISNULL(@InitSeqID, 0)

IF(@InitSeqID IS NOT NULL)
BEGIN
	DECLARE @num INT = 1
		,@AffID INT = 0
		,@DepositCustID INT = 0;

	SELECT ROW_NUMBER() OVER(ORDER BY DepositCustID ASC) AS NUM
		,DepositCustID
		, EUAffID
	INTO #tmpPlayers
	FROM [dbo].[EUAffPlayers]

	WHILE(EXISTS(SELECT TOP 1 1 FROM #tmpPlayers WHERE NUM = @num))
	BEGIN
			
		SELECT TOP (1) @DepositCustID = DepositCustID 
		FROM #tmpPlayers 
		WHERE NUM = @num

		SELECT @InitSeqID = @InitSeqID + 1;
		
		INSERT INTO dbo.SeqClickStats(SeqID, DepositCustID, SeqDate)
		VALUES (@InitSeqID, @DepositCustID, GETDATE());		
		
		SET @num += 1;
	END

	-- insert ClickStatistics
	-- SET IDENTITY_INSERT to ON.
	SET IDENTITY_INSERT dbo.ClickStatistics ON;
	INSERT INTO 
	[dbo].[ClickStatistics1]
		([ClickID]
		,[AffID]
		,[UpdatedTime]
		,[IP]
		,[Date]
		,[Browser]
		,[URLReferrer]
		,[DomainReferrer]
		,[OS]
		,[Device]
		,[BrowserVersion]
		,[BrowserResolution]
		,[BrowserLanguage]
		,[UserAgent]
		,[Country]
		,[LanguageCode]
		,[SportCode]
		,[RedirectURL]
		,[Status])
	SELECT seq.SeqID
		,ai.AffID							--<AffID, int,>
		,seq.SeqDate						--<UpdatedTime, datetime,>
		,'127.0.0.1'						--<IP, varchar(23),>
		,CAST(seq.SeqDate AS smalldatetime)	--<Date, smalldatetime,>
		,'N/A'								--<Browser, nvarchar(50),>
		,'N/A'								--<URLReferrer, nvarchar(300),>
		,'N/A'								--<DomainReferrer, nvarchar(300),>
		,'N/A'								--<OS, nvarchar(50),>
		,'N/A'								--<Device, nvarchar(50),>
		,'N/A'								--<BrowserVersion, nvarchar(16),>
		,'N/A'								--<BrowserResolution, nvarchar(16),>
		,'N/A'								--<BrowserLanguage, nvarchar(8),>
		,'N/A'								--<UserAgent, nvarchar(256),>
		,'N/A'								--<Country, nvarchar(256),>
		,'N/A'								--<LanguageCode, varchar(10),>
		,'N/A'								--<SportCode, varchar(50),>
		,'N/A'								--<RedirectURL, nvarchar(256),>
		,0									--<Status, tinyint,>
	FROM #tmpPlayers mem
	INNER JOIN dbo.SeqClickStats seq WITH(NOLOCK) 
		ON mem.DepositCustID = seq.DepositCustID
	INNER JOIN dbo.AffInfo ai WITH(NOLOCK) 
		ON mem.EUAffID = ai.EUAffID

	SET IDENTITY_INSERT dbo.ClickStatistics1 OFF;

	DROP TABLE #tmpPlayers;
	PRINT 'SeqClickStats init sucessed.'

	select * from dbo.SeqClickStats;
	
END
ELSE
	PRINT 'SeqClickStats init failed.'
