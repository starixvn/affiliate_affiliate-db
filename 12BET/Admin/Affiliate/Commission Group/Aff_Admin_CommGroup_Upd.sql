/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_Admin_CommGroup_Upd]
	@UserId			INT,
	@GroupId		INT,
	@GroupName		NVARCHAR(100) = NULL,
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

	SELECT @GroupName = LTRIM(RTRIM(ISNULL(@GroupName, '')))
	
	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupId = @GroupId)
	BEGIN
		-- Group is not existed
		SELECT @ErrCode = 100, @ErrMsg = dbo.Aff_f_GetMessageById(1006, @Language)

		RETURN
	END

	IF @GroupName = ''
	BEGIN
		-- Group name is invalid!
		SELECT @ErrCode = 101, @ErrMsg = dbo.Aff_f_GetMessageById(1001, @Language)

		RETURN
	END

	IF EXISTS (SELECT 1 FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsDeleted = 0 AND GroupId <> @GroupId)
	BEGIN
		-- Group name is already existed
		SELECT @ErrCode = 102, @ErrMsg = dbo.Aff_f_GetMessageById(1002, @Language)

		RETURN
	END

	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))

	-- QMTurnover
	DECLARE @NextQMTurnover MONEY
	SELECT  @NextQMTurnover = @QMTurnover -- update next only

	-- Deductions
	DECLARE @DeductionSetting TABLE (NextGroupProductId TINYINT, DeductionId TINYINT, ProductId INT, NextDeductedPercentage DECIMAL(9,8))
	
	;WITH CTE_DeductionSetting AS
	(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY t.c.value('@id', 'TINYINT') ORDER BY (SELECT NULL)) AS NextGroupProductId,
			t.c.value('@id', 'TINYINT') AS DeductionId,
			t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
			t.c.value('@percent', 'DECIMAL(9,8)') AS NextDeductedPercentage
		FROM @DeductionList.nodes('/root/row') AS t(c)
	)
	INSERT INTO @DeductionSetting (NextGroupProductId, DeductionId, ProductId, NextDeductedPercentage)
	SELECT ds.NextGroupProductId, ds.DeductionId, f.val, ds.NextDeductedPercentage
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

	DECLARE @updateData TABLE
	(
		-- 1: general, 2: tier, 3: deduction
		TypeId					TINYINT,
		-- General information
		GroupName				NVARCHAR(100),
		Description				NVARCHAR(100),
		NextQMTurnover			MONEY,
		-- Tier List
		TierId					TINYINT,
		MinAmount				MONEY,
		MaxAmount				MONEY,
		MinQM					INT,
		MaxQM					INT,
		Commission				DECIMAL(9,8),
		-- Deduction List
		NextGroupProductId	TINYINT,
		DeductionId				TINYINT,
		ProductId				INT,
		NextDeductedPercentage	DECIMAL(9,8)
	)

	-- General information
	BEGIN TRY
		UPDATE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
		SET GroupName = @GroupName,
			Description = @Description,
			NextQMTurnover = ISNULL(@NextQMTurnover, 0)
		OUTPUT DELETED.GroupName,DELETED.Description,DELETED.NextQMTurnover,1
		INTO @updateData (GroupName,Description,NextQMTurnover,TypeId)
		WHERE GroupId = @GroupId

		UPDATE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
		SET GroupName = GroupName,
			Description = @Description
		WHERE GroupId = @GroupId
			AND MonthDate = @MonthDate
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET GroupName		= up.GroupName,
			Description		= up.Description,
			NextQMTurnover	= up.NextQMTurnover
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND TypeId = 1

		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET GroupName	= up.GroupName,
			Description = up.Description
		FROM dbo.CommGroupHistory cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId AND cg.MonthDate = @MonthDate
			AND TypeId = 1
		
		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Tier List
	BEGIN TRY
		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			OUTPUT DELETED.TierId,DELETED.MinAmount,DELETED.MaxAmount,DELETED.MinQM,DELETED.MaxQM,DELETED.Commission,2
			INTO @updateData (TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission,TypeId)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @TierSetting
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET Description = up.Description,
			NextQMTurnover = up.NextQMTurnover
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND up.TypeId = 1

		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET Description = up.Description
		FROM dbo.CommGroupHistory cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId AND cg.MonthDate = @MonthDate
			AND up.TypeId = 1

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @updateData
		WHERE TypeId = 2

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @updateData
		WHERE TypeId = 2

		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Deduction List
	BEGIN TRY
		DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId
		
		MERGE dbo.DeductionSetting AS TARGET
		USING @DeductionSetting AS SOURCE
			ON		TARGET.GroupId			= @GroupId
				AND TARGET.DeductionId		= SOURCE.DeductionId
				AND TARGET.ProductId		= SOURCE.ProductId
		WHEN MATCHED THEN
			UPDATE SET
				TARGET.NextDeductedPercentage	= SOURCE.NextDeductedPercentage,
				TARGET.NextGroupProductId		= SOURCE.NextGroupProductId
		WHEN NOT MATCHED BY TARGET THEN
			INSERT
			(
				GroupId,DeductionId,ProductId,NextDeductedPercentage,NextGroupProductId
			)
			VALUES
			(
				@GroupId,SOURCE.DeductionId,SOURCE.ProductId,SOURCE.NextDeductedPercentage,SOURCE.NextGroupProductId
			)
		WHEN NOT MATCHED BY SOURCE AND TARGET.GroupId = @GroupId THEN
			DELETE
		OUTPUT DELETED.DeductionId,DELETED.ProductId,DELETED.NextDeductedPercentage,DELETED.NextGroupProductId,3
		INTO @updateData (DeductionId,ProductId,NextDeductedPercentage,NextGroupProductId,TypeId);
	END TRY
	BEGIN CATCH
		-- Rollback manually
		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET cg.Description = up.Description,
			cg.NextQMTurnover = up.NextQMTurnover
		FROM dbo.CommGroup cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId
			AND up.TypeId = 1

		UPDATE cg WITH (ROWLOCK, UPDLOCK)
		SET Description = up.Description
		FROM dbo.CommGroupHistory cg
			CROSS APPLY @updateData up
		WHERE cg.GroupId = @GroupId AND cg.MonthDate = @MonthDate
			AND up.TypeId = 1

		DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId

		DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
		WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		INSERT INTO dbo.TierSetting (GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @updateData
		WHERE TypeId = 2

		INSERT INTO dbo.TierSettingHistory (GroupId,MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission)
		SELECT @GroupId,@MonthDate,TierId,MinAmount,MaxAmount,MinQM,MaxQM,Commission
		FROM @updateData
		WHERE TypeId = 2

		-- Failed to update group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1007, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @OldData NVARCHAR(MAX), @NewData NVARCHAR(MAX)

	DECLARE @OldDeductionList XML, @OldTierList XML

	SELECT  @OldTierList = 
		(
			SELECT
				TierId		AS '@id',
				MinAmount	AS '@minamount',
				MaxAmount	AS '@maxamount',
				MinQM		AS '@minqm',
				MaxQM		AS '@maxqm',
				Commission	AS '@commission'
			FROM @updateData
			WHERE TypeId = 3
			FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldDeductionList = 
		(
			SELECT
				DeductionId				AS '@id',
				ProductIds				AS '@productids',
				NextDeductedPercentage	AS '@nextpercent'
			FROM
			(
				SELECT
					DeductionId,
					NextDeductedPercentage,
					STUFF(
						(SELECT	',' + CONVERT(VARCHAR(10), up.ProductId)
							FROM @updateData up
							WHERE up.DeductionId = ud.DeductionId
								AND up.NextDeductedPercentage = ud.NextDeductedPercentage
								AND up.NextGroupProductId = ud.NextGroupProductId
							FOR XML PATH (''))
							, 1, 1, '') AS ProductIds
				FROM @updateData ud
				WHERE TypeId = 2
			) AS u
			FOR XML PATH('row'), ROOT('root')		
		)

	SELECT  @OldData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(GroupName, '') + ',' +
		'Description='		+ ISNULL(Description, '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @OldDeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @OldTierList), '') + ',' +
		'NextQMTurnover='	+ ISNULL(CONVERT(NVARCHAR(MAX), NextQMTurnover), '')
	FROM @updateData

	SELECT  @NewData =
		'GroupId='			+ ISNULL(CONVERT(VARCHAR(15), @GroupId), '') + ',' +
		'GroupName='		+ ISNULL(@GroupName, '') + ',' +
		'Description='		+ ISNULL(@Description, '') + ',' +
		'DeductionList='	+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='			+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '') + ',' +
		'NextQMTurnover='	+ ISNULL(CONVERT(NVARCHAR(MAX), @NextQMTurnover), '')
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId,
		@AffId		= 0,
		@SPName		= @SPName,
		@OldData	= @OldData,
		@NewData	= @NewData,
		@IP			= @IP,
		@Language	= @Language
END
GO