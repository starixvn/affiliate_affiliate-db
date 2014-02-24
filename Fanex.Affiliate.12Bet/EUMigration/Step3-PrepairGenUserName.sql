/*
	Task : 12Bet - EU migration: Generate 12Bet UserName
	Author : Bobby.Nguyen@20140124
	DB: Affiliate_12Bet
*/

USE [Affiliate_12BET];
GO

IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'SeqAffInfo'
			)
		) DROP TABLE [dbo].[SeqAffInfo];

--init SeqAffInfo
CREATE TABLE dbo.SeqAffInfo (
	SeqID INT 
	,AffID INT
	,EUAffID INT
	,SeqDate DATETIME,
	CONSTRAINT [PK_SeqAffInfo] PRIMARY KEY CLUSTERED 
	(
		[SeqID] ASC
	) WITH (PAD_INDEX = OFF, STATISTICS_NORECOMPUTE = OFF, IGNORE_DUP_KEY = OFF, ALLOW_ROW_LOCKS = ON, ALLOW_PAGE_LOCKS = ON) ON [PRIMARY]
) ON [PRIMARY];

--initial SeqID
DECLARE @UserName VARCHAR(30)
	,@AffPrefix VARCHAR(20)
	,@InitSeqID INT
	,@InitAffID INT;

SET @AffPrefix = '12BetAff'

SELECT @UserName = UserName
	, @InitAffID = ISNULL(AffID, 0)
FROM dbo.AffInfo WITH (NOLOCK)
WHERE AffID = (SELECT MAX(ISNULL(AffID, 0))
				FROM AffInfo WITH (NOLOCK)
				WHERE UserName LIKE @AffPrefix + '%')

SET @UserName	= ISNULL(@UserName, @AffPrefix + '00000');
SET @InitAffID	= ISNULL(@InitAffID, 0);

SET @InitSeqID = CAST(SUBSTRING(@UserName, (LEN(@AffPrefix) + 1), 10) AS INT);

IF(@InitSeqID IS NOT NULL)
BEGIN
	DECLARE @num INT = 1
		,@EUAffID INT = 0;

	SELECT ROW_NUMBER() OVER(ORDER BY EUAffID ASC) AS NUM, 
		EUAffID
	INTO #tmpAff
	FROM [dbo].[EUAffiliates]

	WHILE(EXISTS(SELECT TOP 1 1 FROM #tmpAff WHERE NUM = @num))
	BEGIN
			
		SELECT TOP 1 @EUAffID = EUAffID 
		FROM #tmpAff 
		WHERE NUM = @num

		SELECT @InitSeqID = @InitSeqID + 1
			, @InitAffID = @InitAffID + 1;
		
		INSERT INTO dbo.SeqAffInfo(SeqID, AffID, EUAffID, SeqDate)
		VALUES (@InitSeqID, @InitAffID, @EUAffID, GETDATE());

		SET @num += 1;
	END

	DROP TABLE #tmpAff;
	PRINT 'SeqAffInfo init sucessed.'

	select * from dbo.SeqAffInfo;
END
ELSE
	PRINT 'SeqAffInfo init failed.'
