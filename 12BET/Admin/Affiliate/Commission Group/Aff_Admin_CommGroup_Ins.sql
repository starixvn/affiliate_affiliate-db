/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Ins]
	@UserId			INT,
	@GroupId		INT = 0 OUTPUT, -- using for private group
	@GroupName		NVARCHAR(100),
	@Description	NVARCHAR(100) = NULL,
	@DeductionList	XML,
	@TierList		XML,
	@QMTurnover		MONEY,
	@IP				NVARCHAR(20) = '',
	@ErrCode		INT = 0 OUTPUT,
	@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Admin site - Add new commission group

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]

	Parameter's Explanation:
		- @GroupId:
			= 0: Normal Group
			<>0: Private Group
		- @DeductionList:
			<root>
				<row id="10" productids = "1,2,3" percent="0.17" />
				<row id="10" productids = "4,5" percent="0.15" />
				<row id="11" productids = "0" percent="0.07" />
				<row id="12" productids = "0" percent="0.02" />
			</root>
		- @TierList:
			<root>
				<row id="1" minamount="0" maxamount="100" minqm="0" maxqm="5" commission="0.2" />
				<row id="2" minamount="101" maxamount="100000000000000" minqm="6" maxqm="1000000000" commission="0.3" />
			</root>
		- Note: Infinite value of MaxAmount is 100,000,000,000,000 and MaxQM is 1,000,000,000
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[CommissionGroup]',
		@System		= 'AFFILIATE',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	SELECT @GroupName = LTRIM(RTRIM(ISNULL(@GroupName, '')))
	
	IF ISNULL(@GroupId, 0) <> 0
	BEGIN
		SELECT @GroupName = Username, @Description = NULL
		FROM dbo.AffInfo WITH (NOLOCK)
		WHERE AffId = @GroupId

		IF EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId)
		BEGIN
			DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId

			DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId AND MonthDate = @MonthDate

			DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId

			DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId AND MonthDate = @MonthDate

			DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId

			DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @GroupId AND MonthDate = @MonthDate
		END
	END
	ELSE
	BEGIN
		IF @GroupName = ''
		BEGIN
			-- Group name is invalid!
			SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1001, @Language)

			RETURN
		END

		IF EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsDeleted = 0)
		BEGIN
			-- Group name is already existed
			SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1002, @Language)

			RETURN
		END

		SELECT  @GroupId = MAX(GroupId)
		FROM dbo.CommGroup WITH (NOLOCK)
		WHERE GroupId < 1000

		SELECT @GroupId = @GroupId + 1
	END

	-- Deductions
	DECLARE @DeductionSetting TABLE (GroupProductId TINYINT, DeductionId TINYINT, ProductId INT, DeductedPercentage DECIMAL(9,8))
	
	;WITH CTE_DeductionSetting AS
	(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY t.c.value('@id', 'TINYINT') ORDER BY (SELECT NULL)) AS GroupProductId,
			t.c.value('@id', 'TINYINT') AS DeductionId,
			t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
			t.c.value('@percent', 'DECIMAL(9,8)') AS DeductedPercentage
		FROM @DeductionList.nodes('/root/row') AS t(c)
	)
	INSERT INTO @DeductionSetting (GroupProductId, DeductionId, ProductId, DeductedPercentage)
	SELECT GroupProductId, ds.DeductionId, f.val, ds.DeductedPercentage
	FROM CTE_DeductionSetting ds
		CROSS APPLY dbo.Aff_f_StringSplit(ds.ProductIds, ',') f
	OPTION (OPTIMIZE FOR (@DeductionList = NULL), MAXRECURSION 0)

	-- Tier Setting
	DECLARE @TierSetting TABLE (TierID TINYINT, MinAmount MONEY, MaxAmount MONEY, MinQM INT, MaxQM INT, Commission DECIMAL(9,8))
	
	INSERT INTO @TierSetting (TierID, MinAmount, MaxAmount, MinQM, MaxQM, Commission)
	SELECT
		t.c.value('@id', 'TINYINT'),
		t.c.value('@minamount', 'MONEY'),
		t.c.value('@maxamount', 'MONEY'),
		t.c.value('@minqm', 'INT'),
		t.c.value('@maxqm', 'INT'),
		t.c.value('@commission', 'DECIMAL(9,8)')
	FROM @TierList.nodes('/root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@TierList = NULL))

	-- Check valid tier setting
	IF (SELECT COUNT(1) FROM @TierSetting) > 50
	BEGIN
		-- Oops, maximum of 50 tiers are allowed!
		SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1003, @Language)

		RETURN
	END

	DECLARE @Infinity_Amount MONEY = 100000000000000, @Inifinity_QM INT = 1000000000
	IF EXISTS
		(
			SELECT 1
			FROM @TierSetting ts1
				INNER JOIN @TierSetting ts2 ON ts1.TierID + 1 = ts2.TierID
			WHERE ts1.MaxAmount + 1 <> ts2.MinAmount
		)
		OR NOT EXISTS
		(
			SELECT 1 FROM @TierSetting WHERE MaxAmount = @Infinity_Amount
		)
		OR NOT EXISTS
		(
			SELECT 1 FROM @TierSetting WHERE TierId = 1 AND MinAmount = 0
		)
	BEGIN
		-- Error! Invalid Tier Setting!
		SELECT @ErrCode = 104, @ErrMsg = dbo.Aff_f_GetMessageById(1004, @Language)

		RETURN
	END

	-- General information
	BEGIN TRY
		INSERT INTO dbo.CommGroup
		(
			GroupId,
			GroupName,
			CreatedDate,
			Creator,
			IsDeleted,
			Description,
			QMTurnover,
			NextQMTurnover
		)
		VALUES
		(
			@GroupId,
			@GroupName,
			GETDATE(),
			@UserId,
			0,
			@Description,
			@QMTurnover,
			@QMTurnover -- default of next = current
		)

		INSERT INTO dbo.CommGroupHistory
		(
			GroupId,
			MonthDate,
			GroupName,
			CreatedDate,
			Creator,
			IsDeleted,
			Description,
			QMTurnover
		)
		VALUES
		(
			@GroupId,
			@MonthDate,
			@GroupName,
			GETDATE(),
			@UserId,
			0,
			@Description,
			@QMTurnover
		)
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Tier List
	BEGIN TRY
		INSERT INTO dbo.TierSetting
		(
			GroupId,
			TierId,
			MinAmount,
			MaxAmount,
			MinQM,
			MaxQM,
			Commission
		)
		SELECT
			@GroupId,
			TierId,
			MinAmount,
			MaxAmount,
			MinQM,
			MaxQM,
			Commission
		FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory
		(
			GroupId,
			MonthDate,
			TierId,
			MinAmount,
			MaxAmount,
			MinQM,
			MaxQM,
			Commission
		)
		SELECT
			@GroupId,
			@MonthDate,
			TierId,
			MinAmount,
			MaxAmount,
			MinQM,
			MaxQM,
			Commission
		FROM @TierSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Deduction List
	BEGIN TRY
		INSERT INTO dbo.DeductionSetting
		(
			GroupId,
			GroupProductId,
			NextGroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage,
			NextDeductedPercentage
		)
		SELECT
			@GroupId,
			GroupProductId,
			GroupProductId, -- default of next = current
			DeductionId,
			ProductId,
			DeductedPercentage,
			DeductedPercentage -- default of next = current
		FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory
		(
			GroupId,
			MonthDate,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage
		)
		SELECT
			@GroupId,
			@MonthDate,
			GroupProductId,
			DeductionId,
			ProductId,
			DeductedPercentage
		FROM @DeductionSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT  @Data =
		'GroupName='	+ ISNULL(@GroupName, '') + ',' +
		'Description='	+ ISNULL(@Description, '') + ',' +
		'DeductionList='+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='		+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '') + ',' +
		'QMTurnover='	+ ISNULL(CONVERT(NVARCHAR(MAX), @QMTurnover), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@NewData	= @Data,
		@IP			= @IP,
		@Language	= @Language
END
GO