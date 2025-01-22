/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20241230@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		2. Migrate Group Comm of AFF				
*/


USE Affiliate_12B
GO


	DECLARE @DefaultGroupId_V2		INT		= NULL
		,@NoCommissionGroupId_V2	INT		= NULL
		,@DefaultGroupName_V2 NVARCHAR(100)	= 'Default Comm Group' 
		,@NoCommissionName_V2 NVARCHAR(100)	= 'NoCommission'
		,@DefaultGroupName_V1 NVARCHAR(100)	= 'Default Comm Group' 
		,@NoCommissionName_V1 NVARCHAR(100)	= 'NoCommission'
		,@DefaultGroupId_V1			INT		= NULL
		,@NoCommissionGroupId_V1	INT		= NULL
		,@MessageError VARCHAR(50)			= NULL
		,@ErrorCode INT						= 0
		,@MontDate SMALLDATETIME			

	SET @MontDate = EOMONTH(GETDATE())

	SELECT @DefaultGroupId_V2 =  GroupId 
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = @DefaultGroupName_V2
	;
	SELECT @NoCommissionGroupId_V2 = GroupId
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = @NoCommissionName_V2
	
	SELECT @DefaultGroupId_V1 = GroupId 
	FROM Affiliate_12BET.dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = @DefaultGroupName_V1


	SELECT @NoCommissionGroupId_V1	=  GroupId 
	FROM Affiliate_12BET.dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = @NoCommissionName_V1

	IF (@DefaultGroupId_V2 IS NULL OR @NoCommissionGroupId_V2 IS NULL OR @DefaultGroupId_V1 IS NULL OR  @NoCommissionGroupId_V1 IS NULL)
	BEGIN
		SET @ErrorCode = 1
		GOTO STOP_SCRIPT;
	END

	CREATE TABLE #AFFInfoUpdate (Row_num INT IDENTITY(1,1),AffId INT, Old_GroupId INT, New_GroupId INT)
	;WITH CTE_AFFInfo AS(
		SELECT AffId
		FROM dbo.AffInfo WITH(NOLOCK)
		WHERE GroupId <> 0
			AND UserName NOT IN ('12BETAFF001'
				,'12BETAFF030'
				,'12BETAFF078')
	)
	INSERT INTO #AFFInfoUpdate( AffId, Old_GroupId, New_GroupId)
	SELECT c.AffId, c.GroupId, CASE WHEN c.GroupId = @NoCommissionGroupId_V1 THEN @NoCommissionGroupId_V2 ELSE @DefaultGroupId_V2 END 									
	FROM  Affiliate_12BET.dbo.AffGroupHistory c WITH(NOLOCK)
		INNER JOIN CTE_AFFInfo a ON c.AffId = a.AffId
	WHERE c.MonthDate = @MontDate


	------ info for deployer
DECLARE @StartRow	INT 
	, @StopRow		INT 
	, @MaxRow		INT	= 0
	, @Threshold	INT  -- the number of each batch
SET @Threshold		= 4000
 
SELECT @MaxRow = MAX(Row_num) 
FROM #AFFInfoUpdate

IF (@Threshold >= @MaxRow)
	SET @Threshold = @MaxRow

-- SET for first batch
SELECT @StartRow = 1, @StopRow = @Threshold

WHILE (@MaxRow IS NOT NULL)
BEGIN
	
		PRINT @StartRow
		PRINT @StopRow
		
		-- YOUR CODE PROCESS FOR DATA FROM @StartRow & @StopRow
		UPDATE c SET GroupId = a.New_GroupId
		FROM dbo.AffInfo c WITH (UPDLOCK, ROWLOCK)
			INNER JOIN #AFFInfoUpdate a ON c.affId = a.AffId
		WHERE a.Row_num BETWEEN @StartRow AND @StopRow
		;
		UPDATE c SET GroupId = a.New_GroupId
		FROM dbo.AffGroupHistory c WITH (UPDLOCK, ROWLOCK)
			INNER JOIN #AFFInfoUpdate a ON c.affId = a.AffId AND c.MonthDate = @MontDate
		WHERE a.Row_num BETWEEN @StartRow AND @StopRow

		SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
		RAISERROR (@MessageError, 0, 1) WITH NOWAIT
		
		IF @StopRow = @MaxRow BREAK

		WAITFOR DELAY '00:00:00.100' --optional

		SET @StartRow = @StopRow + 1
		SET @StopRow = @StopRow + @Threshold
		IF @StopRow >= @MaxRow
			SET @StopRow = @MaxRow
END

	STOP_SCRIPT:
	IF (@ErrorCode <> 0)
		PRINT 'Fail Migrate'
	ELSE
		PRINT 'Complete Migrate'

	DROP TABLE IF EXISTS #AFFInfoUpdate


