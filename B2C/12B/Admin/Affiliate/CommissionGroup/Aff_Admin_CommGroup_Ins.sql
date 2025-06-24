/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_CommGroup_Ins]
	@UserId				INT
	,@GroupId			INT = 0 OUTPUT
	,@SubCommRate		DECIMAL(9,8)
	,@IsPrivate			BIT = 0
	,@GroupName			NVARCHAR(100) = ''
	,@GroupTypeId		INT = 1
	,@Description		NVARCHAR(100) = NULL
	,@DeductionList		XML = NULL
	,@TierList			XML = NULL
	,@StraightList		XML = NULL
	,@QMTurnover		MONEY
	,@IsActivePlayerSum BIT
	,@IP				VARCHAR(50) = ''
	,@ErrCode			INT = 0 OUTPUT
	,@ErrMsg			NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Add new commission group

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250319@Sally: Allow Negative MinNetWinlos Amount [RedmineID: #219936]
		- 20250623@Sally: Enhance Revenue calculation [RedmineID: #231221]

	Parameter's Explanation:
		- @DeductionList xml = N'
			<root>
				<row id="10" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125" percent="0.12" amount="0" isdeductedpercent="True"/>
				<row id="10" productids="1" percent="0.01" amount="0" isdeductedpercent="True"/>
				<row id="10" productids="2" percent="0.007" amount="0" isdeductedpercent="True"/>
				<row id="13" productids="" percent="0.03" amount="0" isdeductedpercent="True"/>
				<row id="14" productids="" percent="0.03" amount="0" isdeductedpercent="True"/>
			</root>'
		- @TierList xml = N'
			<root>
				<row id="1" minamount="-100000000000" minqm="5" commission="0.025" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="2" minamount="-500000" minqm="5" commission="0.015" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="3" minamount="1" minqm="5" commission="0.015" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="4" minamount="6" minqm="10" commission="0.126" productids="3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,33,34,35,36,37,38,39,40,41,42,44,45,46,47,48,49,50,51,52,53,54,55,56,57,58,59,60,61,62,63,64,65,66,67,68,69,70,71,73,74,75,76,77,78,79,80,81,82,83,84,85,86,87,88,89,90,91,93,94,95,96,97,98,99,100,101,102,103,104,105,106,107,108,109,110,111,112,113,114,115,116,117,119,120,121,122,123,124,125"/>
				<row id="1" minamount="0" minqm="5" commission="0.03" productids="1"/>
				<row id="1" minamount="0" minqm="5" commission="0" productids="2"/>
				<row id="2" minamount="100" minqm="5" commission="0" productids="2"/>
				<row id="3" minamount="120" minqm="5" commission="0" productids="2"/>
			</root>'
		- Note: 
			+ Infinite value of MaxAmount is 100,000,000,000
			+ MinAmount is -100,000,000,000 
			+ MaxAM is 1,000,000,000
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @Language NVARCHAR(5) = 'en-US'

	-- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[RevenueGroup]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	-- last date of current month
	DECLARE @MonthDate SMALLDATETIME
	SELECT  @MonthDate = EOMONTH(GETDATE())
	DECLARE @Infinity_NegativeAmount MONEY = -100000000000
		,@Infinity_PositiveAmount MONEY    = 100000000000
		,@Inifinity_QM INT 				   = 1000000000

	SELECT @GroupName = TRIM(ISNULL(@GroupName, ''))

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

	-- Deductions
	DECLARE @GroupProduct TABLE (GroupProductId TINYINT, ProductIds VARCHAR(MAX))
	DECLARE @DeductionSetting TABLE (GroupProductId TINYINT, DeductionId TINYINT, ProductId INT, DeductedPercentage DECIMAL(9,8), DeductedAmount MONEY, IsDeductedPercent BIT)
	
	;WITH CTE_DeductionSetting AS
	(
		SELECT
			ROW_NUMBER() OVER(PARTITION BY t.c.value('@id', 'TINYINT') ORDER BY (SELECT NULL)) AS GroupProductId,
			t.c.value('@id', 'TINYINT') AS DeductionId,
			t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
			t.c.value('@percent', 'DECIMAL(9,8)') AS DeductedPercentage,
			t.c.value('@amount', 'MONEY') AS DeductedAmount,
			t.c.value('@isdeductedpercent', 'BIT') AS IsDeductedPercent
		FROM @DeductionList.nodes('/root/row') AS t(c)
	)
	INSERT INTO @DeductionSetting (GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
	SELECT GroupProductId, ds.DeductionId, ISNULL(CONVERT(INT, f.value), 0), ISNULL(ds.DeductedPercentage, 0), ISNULL(ds.DeductedAmount, 0), ISNULL(ds.IsDeductedPercent, 0)
	FROM CTE_DeductionSetting ds
		OUTER APPLY STRING_SPLIT(dbo.Aff_f_AddRelatedProducts(ds.ProductIds), ',') f
	OPTION (OPTIMIZE FOR (@DeductionList = NULL), MAXRECURSION 0)

	UPDATE @DeductionSetting
	SET DeductedPercentage	= CASE WHEN IsDeductedPercent = 0 THEN 0 ELSE ISNULL(DeductedPercentage, 0) END
		,DeductedAmount		= CASE WHEN IsDeductedPercent = 1 THEN 0 ELSE ISNULL(DeductedAmount, 0) END

	-- Tier Setting
	DECLARE @TierSetting TABLE (TierID TINYINT, productids VARCHAR(MAX), GroupProductId TINYINT, MinAmount MONEY, MaxAmount MONEY, MinQM INT, MaxQM INT, Commission DECIMAL(9,8), IsNegativeAmount BIT)
	
	INSERT INTO @TierSetting (TierID, productids, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsNegativeAmount)
	SELECT
		t.c.value('@id', 'TINYINT'),
		t.c.value('@productids', 'VARCHAR(MAX)') AS ProductIds,
		t.c.value('@minamount', 'MONEY'),
		t.c.value('@maxamount', 'MONEY'),
		t.c.value('@minqm', 'INT'),
		@Inifinity_QM AS MaxQM,
		t.c.value('@commission', 'DECIMAL(9,8)'),
        CASE WHEN t.c.value('@minamount', 'MONEY') < 0 THEN 1 ELSE 0 END AS IsNegativeAmount
	FROM @TierList.nodes('/root/row') AS t(c)
	OPTION (OPTIMIZE FOR (@TierList = NULL))
	
	-- Update Group of Products
	UPDATE t	
	SET t.GroupProductId = l.GroupProductId
	FROM @TierSetting t
	CROSS APPLY (
		SELECT TOP 1 d.GroupProductId
		FROM @DeductionSetting d 
		WHERE ',' + t.productids + ',' LIKE '%,' + CONVERT(VARCHAR(20), d.ProductId) + ',%'
	) AS l

	-- Update MaxAmount for each tier of each products's group
	UPDATE t1
	SET t1.MaxAmount = t2.MinAmount
	FROM @TierSetting t1
		INNER JOIN @TierSetting t2 ON t1.TierID + 1 = t2.TierID AND t1.GroupProductId = t2.GroupProductId
	
	;WITH CTE AS
	(
		SELECT GroupProductId, MAX(TierID) AS TierID FROM @TierSetting GROUP BY GroupProductId
	)
	UPDATE t
	SET t.MaxAmount = @Infinity_PositiveAmount
	FROM @TierSetting t
		INNER JOIN CTE e ON t.TierID = e.TierID AND t.GroupProductId = e.GroupProductId

	-- Check valid tier setting
    BEGIN
        IF EXISTS (SELECT 1 FROM @TierSetting GROUP BY GroupProductId HAVING COUNT(1) > 50) 
        BEGIN
            -- Oops, maximum of 50 tiers are allowed!
            SELECT @ErrCode = 103, @ErrMsg = dbo.Aff_f_GetMessageById(1003, @Language)
            RETURN
        END
        
        IF EXISTS(
            SELECT TOP 1 1 FROM @TierSetting WHERE TierId = 1 AND MinAmount > 0
        )
		OR EXISTS(
			SELECT TOP 1 1 FROM  @TierSetting WHERE TierId = 1 AND IsNegativeAmount =  1 AND MinAmount <> @Infinity_NegativeAmount
		)
        BEGIN
            -- 'The first Tier of the Min Net Win column must be = 0 or -∞'
            SELECT @ErrCode = 201, @ErrMsg = dbo.Aff_f_GetMessageById(1010, @Language)
            RETURN
        END       

        IF EXISTS (
			SELECT TOP 1 1
            FROM (
				SELECT GroupProductId, MAX(TierID) AS TierID
				FROM @TierSetting
				WHERE IsNegativeAmount = 1 
				GROUP BY GroupProductId
			)n 
				INNER JOIN @TierSetting ts1 ON n.GroupProductId = ts1.GroupProductId AND ts1.TierID = n.TierID
				INNER JOIN @TierSetting ts2 ON  ts1.TierID + 1 = ts2.TierID AND ts1.GroupProductId = ts2.GroupProductId
			WHERE ts2.MinAmount = 0 OR ts2.MinAmount >  1
		)               
        BEGIN
            -- The next Tier after a negative Tier must start from 1 in the Min Net Win column.
            SELECT @ErrCode = 202, @ErrMsg = dbo.Aff_f_GetMessageById(1011, @Language)
            RETURN
        END

        IF EXISTS(
				SELECT TOP 1 1
				FROM @TierSetting ts1
					INNER JOIN @TierSetting ts2 ON ts1.TierID + 1 = ts2.TierID AND ts1.GroupProductId = ts2.GroupProductId
				 WHERE ts1.MaxAmount > ts2.MaxAmount 
					OR ts1.MinAmount > ts2.MinAmount 
			)
        BEGIN
            -- The values in the Min Net Win column must increase sequentially.
            SELECT @ErrCode = 203, @ErrMsg = dbo.Aff_f_GetMessageById(1012, @Language)
            RETURN
        END
    END

	IF @IsPrivate = 1
	BEGIN
		DECLARE @ExistsGroupId INT
		SELECT  @ExistsGroupId = GroupId FROM dbo.CommGroup WITH (NOLOCK) WHERE GroupName = @GroupName AND IsPrivate = 1
		
		IF @ExistsGroupId IS NOT NULL
		BEGIN
			DELETE dbo.CommGroup WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.CommGroupHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.TierSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.TierSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId AND MonthDate = @MonthDate

			DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId

			DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
			WHERE GroupId = @ExistsGroupId AND MonthDate = @MonthDate
		END
	END

	BEGIN TRY
		-- General information
		INSERT INTO dbo.CommGroup (GroupName, CreatedDate, Creator, IsPrivate, SubCommRate, Description, GroupTypeId, QMTurnover)
		VALUES (@GroupName, GETDATE(), @UserId, @IsPrivate, @SubCommRate, @Description, @GroupTypeId, @QMTurnover)

		SELECT @GroupId = SCOPE_IDENTITY()

		--History Group
		INSERT INTO dbo.CommGroupHistory (GroupId, MonthDate, SubCommRate, QMTurnover)
		VALUES (@GroupId, @MonthDate, @SubCommRate, @QMTurnover)

		-- Tier List
		INSERT INTO dbo.TierSetting (GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission , @IsActivePlayerSum FROM @TierSetting

		INSERT INTO dbo.TierSettingHistory (GroupId, GroupProductId, MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, IsActivePlayerSum)
		SELECT @GroupId, GroupProductId, @MonthDate, TierId, MinAmount, MaxAmount, MinQM, MaxQM, Commission, @IsActivePlayerSum FROM @TierSetting

		-- Deduction List
		INSERT INTO dbo.DeductionSetting (GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

		INSERT INTO dbo.DeductionSettingHistory (GroupId, MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent)
		SELECT @GroupId, @MonthDate, GroupProductId, DeductionId, ProductId, DeductedPercentage, DeductedAmount, IsDeductedPercent FROM @DeductionSetting

	END TRY
	BEGIN CATCH
		-- Rollback manually
		DELETE dbo.CommGroup WHERE GroupId = @GroupId
		DELETE dbo.CommGroupHistory WITH(ROWLOCK, UPDLOCK) WHERE GroupId = @GroupId 
		DELETE dbo.TierSetting WHERE GroupId = @GroupId
		DELETE dbo.TierSettingHistory WHERE GroupId = @GroupId AND MonthDate = @MonthDate
		DELETE dbo.DeductionSetting WHERE GroupId = @GroupId
		DELETE dbo.DeductionSettingHistory WHERE GroupId = @GroupId AND MonthDate = @MonthDate

		-- Failed to insert new group! Please try again!
		SELECT @ErrCode = 105, @ErrMsg = dbo.Aff_f_GetMessageById(1005, @Language)

		RETURN
	END CATCH

	-- Write log
	DECLARE @SPName VARCHAR(200)
	SELECT  @SPName = OBJECT_NAME(@@PROCID)

	DECLARE @Data NVARCHAR(MAX)

	SELECT  @Data =
		'GroupId='		+ ISNULL(CONVERT(VARCHAR(10), @GroupId), '') + ',' +
		'GroupName='	+ ISNULL(@GroupName, '') + ',' +
		'GroupTypeId='	+ ISNULL(CONVERT(VARCHAR(10), @GroupTypeId), '') + ',' +
		'IsPrivate='	+ ISNULL(CONVERT(VARCHAR(1), @IsPrivate), '') + ',' +
		'Description='	+ ISNULL(@Description, '') + ',' +
		'DeductionList='+ ISNULL(CONVERT(NVARCHAR(MAX), @DeductionList), '') + ',' +
		'TierList='		+ ISNULL(CONVERT(NVARCHAR(MAX), @TierList), '') + ',' +
		'IsActivePlayerSum='+ ISNULL(CONVERT(NVARCHAR(MAX), @IsActivePlayerSum), '') + ',' +
		'SubCommRate='	+ ISNULL(CONVERT(NVARCHAR(MAX), @SubCommRate), '') + ',' +
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