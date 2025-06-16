/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Deal_Del]
	@UserId				INT
	,@GroupId			INT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(MAX) = '' OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Delete Deal

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]

	Parameter's Explanation:

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	DECLARE @Duration INT
	DECLARE @StartTime DATETIME = GETDATE()

	DECLARE @CurrentDate DATETIME = DATEADD(HOUR, 12, GETDATE())
	DECLARE @ActionDate DATETIME =  CAST(@CurrentDate AS DATE)
	DECLARE @ToDate DATETIME = '9999-12-31'

	-- =========================
	-- Check permission
	-- =========================
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Deal]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)

		RETURN
	END

	-- Check group is being used
	IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- At least 1 affiliate was assigned to this group. You cannot delete it.
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1008, @Language)

		RETURN
	END

	--get GroupType, IsInstant
	DECLARE @GroupTypeId TINYINT, @IsInstant BIT
	SELECT @GroupTypeId = GroupTypeId
	FROM CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId

	-- =========================
	-- Delete deal
	-- =========================
	UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
	SET IsDeleted = 1
	WHERE GroupId = @GroupId
	
	-- =========================
	-- Write log
	-- =========================
	DECLARE @EndTime DATETIME = GETDATE()
	SELECT @Duration = DATEDIFF(SECOND, @StartTime, @EndTime)

	-- 1. Deal Info (di)
	DECLARE @DealInfo NVARCHAR(MAX) = (
		SELECT 
			GroupName AS dn,
			CASE WHEN GroupTypeId = 1 THEN 'Revenue Share' WHEN GroupTypeId = 3 THEN 'CPA' ELSE 'Hybrid' END AS dt,
			Description AS d,
			CAST(SubCommRate AS VARCHAR(50)) AS sr
		FROM CommGroup WITH (NOLOCK)
		WHERE GroupId = @GroupId
		FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
	)
	
	-- 2. Revenue/Hybrid (1,4)
	DECLARE @RevenueShareInfo NVARCHAR(MAX) = NULL
	DECLARE @TierJson NVARCHAR(MAX) = NULL

	IF @GroupTypeId IN (1,4)
	BEGIN
		SET @RevenueShareInfo = (
			SELECT 
				QMTurnover AS qpt,
				(SELECT TOP 1 IsActivePlayerSum FROM TierSetting WITH (NOLOCK) WHERE GroupId = @GroupId) AS cqp,
				(SELECT DeductedPercentage FROM DeductionSetting WITH (NOLOCK) WHERE GroupId = @GroupId AND DeductionId IN (13)) AS df,
				(SELECT DeductedAmount FROM DeductionSetting WITH (NOLOCK) WHERE GroupId = @GroupId AND DeductionId IN (13)) AS dfx,
				(SELECT DeductedPercentage FROM DeductionSetting WITH (NOLOCK) WHERE GroupId = @GroupId AND DeductionId IN (14)) AS wf,
				(SELECT DeductedAmount FROM DeductionSetting WITH (NOLOCK) WHERE GroupId = @GroupId AND DeductionId IN (14)) AS wfx
			FROM CommGroup WITH (NOLOCK)
			WHERE GroupId = @GroupId
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		)
		SET @TierJson = (
			SELECT 
				STRING_AGG(CAST(t1.ProductId AS VARCHAR(MAX)), ',') AS rpg,
				t1.DeductedPercentage AS rf,
				(
					SELECT 
						MinAmount AS nw,
						MinQM AS qp,
						Commission AS rs
					FROM TierSetting t2 WITH (NOLOCK)
					WHERE GroupId = @GroupId AND t2.GroupProductId = t1.GroupProductId
					FOR JSON PATH
				) AS rti
			FROM DeductionSetting t1 WITH (NOLOCK)
			WHERE GroupId = @GroupId AND DeductionId = 10
			GROUP BY GroupProductId,t1.DeductedPercentage
			FOR JSON PATH
		)
	END
	
	-- 3. CPA/Hybrid (3,4)
	DECLARE @CPAInfo NVARCHAR(MAX) = NULL
	DECLARE @CPATierJson NVARCHAR(MAX) = NULL

	IF @GroupTypeId IN (3,4)
	BEGIN
		SET @CPAInfo = (
			SELECT 
				CountryCodes AS tc,
				ActiveDays AS ap,
				HoldingDays AS hd,
				HoldingTickets AS ht,
				Quota AS q,
				CASE WHEN IsInstant = 1 THEN 'Yes' ELSE 'No' END AS ip
			FROM CommGroup WITH (NOLOCK)
			WHERE GroupId = @GroupId
			FOR JSON PATH, WITHOUT_ARRAY_WRAPPER
		)
		SET @CPATierJson = (
			SELECT 
				STRING_AGG(CAST(ProductId AS VARCHAR(MAX)), ',') AS cpg,
				(
					SELECT 
						MinFDM AS fd,
						MinTotalDeposit AS td,
						MinTO AS w,
						CPAAmount AS cpa
					FROM CPATierSetting t2 WITH (NOLOCK)
					WHERE t2.GroupId = @GroupId AND t2.ToDate = @ToDate AND t2.GroupProductId = t1.GroupProductId
					FOR JSON PATH
				) AS cti
			FROM CPAProductSetting t1 WITH (NOLOCK)
			WHERE t1.GroupId = @GroupId AND t1.ToDate = @ToDate
			GROUP BY t1.GroupProductId
			FOR JSON PATH
		)
	END
	
	-- 4. Compose @OldData JSON (include only non-null sections)
	DECLARE @OldData NVARCHAR(MAX) = '{'
		+ '"di":' + ISNULL(@DealInfo, '{}')
		+ CASE WHEN @CPAInfo IS NOT NULL THEN ',"ci":' + @CPAInfo ELSE '' END
		+ CASE WHEN @CPATierJson IS NOT NULL THEN ',"ct":' + @CPATierJson ELSE '' END
		+ CASE WHEN @RevenueShareInfo IS NOT NULL THEN ',"ri":' + @RevenueShareInfo ELSE '' END
		+ CASE WHEN @TierJson IS NOT NULL THEN ',"rt":' + @TierJson ELSE '' END
		+ '}'

	-- 5. Write log with Items and NewData

	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= OldData,
		@IP			= @IP,
		@Language	= @Language,
		@Duration	= @Duration
END
GO