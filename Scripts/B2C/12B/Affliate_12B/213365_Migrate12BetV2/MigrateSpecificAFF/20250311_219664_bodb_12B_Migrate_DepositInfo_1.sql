/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250311@Sally
	DB: DB12B-bodb_12B
	Task: Support new Aff 12B [RedmineId : #219664]
		4.2 Initial FDT, FDM for the old customer 12B V1			

*/


USE bodb_12B
GO

DECLARE @StartRow	INT 
	, @StopRow		INT 
	, @MaxRow		INT			= 0
	, @Threshold	INT			-- the number of each batch
	, @MessageError VARCHAR(50)	= NULL
	, @ErrorCode    INT			= 0

SET @Threshold		= 4000
 
 CREATE TABLE #tmpFPDImport (
 	NumRow INT IDENTITY (1,1),
	CustId INT,
	FDT DATETIME,
	FDAmount MONEY,
	CONSTRAINT PK_tmpFPDImport PRIMARY KEY (CustId)
 )
 INSERT INTO #tmpFPDImport(CustId, FDT, FDAmount)
	 SELECT c.CustId, c.FDT, CASE WHEN ct.CurrencyId IN (15, 51) THEN  ISNULL(c.FDAmount, 0) * 1000 ELSE c.FDAmount END AS FDAmount
	 FROM dbo.tmpFPDImport c
		LEFT JOIN dbo.Customer ct WITH (NOLOCK) ON c.CustId = ct.CustId

SELECT @MaxRow = MAX(NumRow) 
FROM #tmpFPDImport

IF (@Threshold >= @MaxRow)
	SET @Threshold = @MaxRow

-- SET for first batch
SELECT @StartRow = 1, @StopRow = @Threshold

WHILE (@MaxRow IS NOT NULL)
BEGIN
		PRINT @StartRow
		PRINT @StopRow
		
		-- YOUR CODE PROCESS FOR DATA FROM @StartRow & @StopRow
		UPDATE c SET c.FirstDepositDate = a.FDT, c.FirstDepositAmount = a.FDAmount
		FROM dbo.Customer c WITH (UPDLOCK, ROWLOCK)
			INNER JOIN #tmpFPDImport a ON c.CustId = a.CustId
		WHERE a.NumRow BETWEEN @StartRow AND @StopRow

		SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
		RAISERROR (@MessageError, 0, 1) WITH NOWAIT
		
		IF @StopRow = @MaxRow BREAK

		WAITFOR DELAY '00:00:00.100' --optional

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @Threshold
		IF @StopRow >= @MaxRow
			SET @StopRow = @MaxRow
END
