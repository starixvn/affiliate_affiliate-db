USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroupUpd] 
	@LicenseeID					INT
	,@UserId					INT
	,@GroupId					INT
	,@Currency					INT
	,@QualifiedAmount			MONEY
	,@GroupName					NVARCHAR(100)
	,@Description				NVARCHAR(100)	= NULL
	,@ProductIDList				VARCHAR(MAX)
	,@DeductionList				VARCHAR(MAX)	= NULL
	,@DeductedPercentageList	VARCHAR(MAX)	= NULL
	,@TierList					VARCHAR(MAX)
	,@MinAmountList				VARCHAR(MAX)
	,@MaxAmountList				VARCHAR(MAX)
	,@MinQMList					VARCHAR(MAX)
	,@MaxQMList					VARCHAR(MAX)
	,@CommissionList			VARCHAR(MAX)
	,@IP						VARCHAR(20)
	,@Language					VARCHAR(5)		= 'en-US'
	,@DepositPercent			FLOAT			= NULL
	,@WithdrawalPercent			FLOAT			= NULL
	,@ErrCode					INT				= 0		OUTPUT
	,@ErrMsg					NVARCHAR(4000)	= ''	OUTPUT
AS

/*  
	Created: 20090719@DungTong  
	Task : update an existing Commission Group  
	DB: DB052.Affiliate_ZZun  
	Original:  
  
	Revisions:  
		- 20131121@Joseph: allow updating currency 'All'
		- 20140312@Peter: Update MemberDaily, AffDaily and AffDailySummary
		- 20140723@Bobby: remove checking @GroupID < 1000
		- 20140820@Bobby: Add Deposit & Withdrawal percent and apply SQL stylescope
		- 20141028@Bobby: hotfix#24904 - remove abs() function for Withdrawal value when calculating PSP fee
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20170601@Percy: Add new column: isTest [RedmineID: #77521]

	Parameters:
		.@UserID : Administrator user id
		.@GroupID:
			-1		: normal group
			>1000	: Special Setting for Affiliate that has AffID = @GroupID
		.@GroupName The name of this Group
		.@Description : description for this group
		.@ProductIDList: list of ProductID separated by semi colon
		.@DeductionList: List of Deduction Setting for above Sport List
		.@DeductedPercentageList: List of Deducted Percentage
		.@TierList: List of number of Tiers for each sport type separated by a semi colon
		.@MinAmountList: List of MinAmount for each tier (all sports)
		.@MaxAmountList: List of MaxAmount for each tier (all sports)
		.@MinQMList: List of MinQM for each tier (all sports)
		.@MaxQMList: List of MaxQM for each tier (all sports)
		.@CommissionList: List of Commission for each tier (all sports)
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT = 0

	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	--Check permission  
	EXEC [dbo].[Aff_Con_CheckPermission]
		@LicenseeID = @LicenseeID
		,@custid = @UserID
		,@funcname = '[CommissionGroup]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT
		,@ErrMsg = @ErrMsg OUTPUT

	IF (@ErrCode <> 0) RETURN

	--Check Currency Permission
	IF (@Currency = 0)
	BEGIN
		IF (dbo.AffAdmin_f_IsITAdmin(@UserID, @LicenseeID) = 0)
			RETURN
	END
	ELSE
	BEGIN
		EXEC [dbo].[AffAdmin_CheckPermissionCurrency] 
			@LicenseeID = @LicenseeID
			,@UserId = @UserID
			,@CurrencyId = @Currency
			,@ErrCode = @ErrCode OUTPUT

		IF (@ErrCode <> 0) RETURN
	END

	IF NOT EXISTS (
		SELECT TOP 1 1 FROM dbo.CommGroup WITH(NOLOCK)
		WHERE GroupID = @GroupID AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 33 --'The group ID ' +  cast(@GroupId as varchar(10)) + ' is not existed. Please check.'         

		RETURN
	END

	IF @GroupName IS NULL OR LTRIM(RTRIM(@GroupName)) = ''
	BEGIN
		SELECT @ErrCode = 34 -- Group name is empty. Please choose a name!

		RETURN
	END

	IF EXISTS (
		SELECT TOP 1 1 FROM dbo.CommGroup WITH(NOLOCK)
		WHERE GroupID <> @GroupID AND GroupName = @GroupName AND IsDeleted = 0
	)
	BEGIN
		SELECT @ErrCode = 35 --Group name existed. Please choose another name!

		RETURN
	END

	-- Check Currency Is different -> do not allow to update when have an Affiliate Assign to this group  
	IF EXISTS (SELECT TOP 1 1 FROM dbo.CommGroup WITH(NOLOCK) WHERE GroupID = @GroupID AND currency <> @Currency)
	BEGIN
		IF (
			EXISTS (SELECT TOP 1 1 FROM dbo.AffCommission WITH(NOLOCK) WHERE GroupID = @GroupID)
			OR EXISTS (SELECT TOP 1 1 FROM dbo.AffInfo ai WITH(NOLOCK) WHERE ai.GroupID = @GroupID)
		)
		BEGIN
			SELECT @ErrCode = 36 --The group has been used. Cannot change the currency. Please check!

			RETURN
		END
	END

	DECLARE @DeductionSetting TABLE
	(
		GroupID 			INT
		,DeductionID 		TINYINT
		,DeductedPercentage FLOAT
	)
	DECLARE @GroupSetting TABLE
	(
		GroupID 	INT
		,ProductID 	TINYINT
		,TierID 	TINYINT
		,MinAmount 	MONEY
		,MaxAmount 	MONEY
		,MinQM 		INT
		,MaxQM 		INT
		,Commission DECIMAL(9, 8)
	)
	
	-- Check for updating Deposit & Withdrawal percent
	SELECT @DepositPercent 		= ISNULL(@DepositPercent, ex.DepositPercent)
		,@WithdrawalPercent		= ISNULL(@WithdrawalPercent, ex.WithdrawalPercent)
	FROM dbo.Exchange ex WITH(NOLOCK)
	WHERE ex.ExchangeId = @Currency
		
	--Insert Deduction Setting  
	IF (LEN(@DeductionList) > 0)
	BEGIN
		INSERT INTO @DeductionSetting (GroupID, DeductionID, DeductedPercentage)
		SELECT @GroupID, CAST(t.val AS TINYINT), CAST(p.val AS FLOAT)
		FROM dbo.strsplit(@DeductionList, ',') t
			INNER JOIN dbo.strsplit(@DeductedPercentageList, ',') p ON p.rank = t.rank
			INNER JOIN DeductionType d WITH (NOLOCK) ON d.DTypeID = CAST(t.val AS TINYINT)
		WHERE d.IsTest <= @isTest

		IF @@ERROR <> 0 OR @@ROWCOUNT <> (SELECT COUNT(1) FROM dbo.strsplit(@DeductionList, ','))
		BEGIN
			SELECT @ErrCode = 37 --Error! Invalid Deduction Setting!

			RETURN
		END
	END

	--Insert Tier Setting  
	DECLARE @rank 		INT
		,@ProductID 	INT
		,@NTier 		INT
		,@i 			INT
		,@MinQM 		INT
		,@MaxQM 		INT
		,@PreMaxQM 		INT
		,@MinAmountArr 	VARCHAR(500)
		,@MaxAmountArr 	VARCHAR(500)
		,@MinQMArr 		VARCHAR(500)
		,@MaxQMArr 		VARCHAR(500)
		,@CommissionArr VARCHAR(500)
		,@MinAmount 	MONEY
		,@MaxAmount 	MONEY
		,@PreMaxAmount 	MONEY
		,@Commission 	DECIMAL(9, 8)
		,@PreCommission	DECIMAL(9, 8)

	SELECT @rank = min(rank)
	FROM dbo.strsplit(@ProductIDList, ';')

	IF @rank IS NOT NULL
	BEGIN
		WHILE @rank IS NOT NULL
		BEGIN
			BEGIN TRY
				--Voi moi ProductID  
				SELECT @ProductID = cast(val AS TINYINT)
				FROM dbo.strsplit(@ProductIDList, ';')
				WHERE rank = @rank

				SELECT @NTier = cast(val AS TINYINT)
				FROM dbo.strsplit(@TierList, ';')
				WHERE rank = @rank

				SELECT @MinAmountArr = val
				FROM dbo.strsplit(@MinAmountList, ';')
				WHERE rank = @rank

				SELECT @MaxAmountArr = val
				FROM dbo.strsplit(@MaxAmountList, ';')
				WHERE rank = @rank

				SELECT @MinQMArr = val
				FROM dbo.strsplit(@MinQMList, ';')
				WHERE rank = @rank

				SELECT @MaxQMArr = val
				FROM dbo.strsplit(@MaxQMList, ';')
				WHERE rank = @rank

				SELECT @CommissionArr = val
				FROM dbo.strsplit(@CommissionList, ';')
				WHERE rank = @rank

				SELECT @i = 1

				IF (@NTier < 1)
				BEGIN
					SELECT @ErrCode = 38 --Error! Invalid Tier List!

					RETURN
				END

				IF (@NTier > 50)
				BEGIN
					ROLLBACK TRANSACTION

					SELECT @ErrCode = 39 --Oops, maximum of 50 tiers are allowed! 

					RETURN
				END

				WHILE @i <= @NTier
				BEGIN
					--Voi moi Tier  
					IF (@i <> 1) --Store previous setting to compare with current setting  
					BEGIN
						SELECT @PreMaxAmount = @MaxAmount
							,@PreMaxQM = @MaxQM
							,@PreCommission = @Commission
					END

					SELECT @MinAmount = cast(val AS MONEY)
					FROM dbo.strsplit(@MinAmountArr, ',')
					WHERE rank = @i

					SELECT @MaxAmount = cast(val AS MONEY)
					FROM dbo.strsplit(@MaxAmountArr, ',')
					WHERE rank = @i

					SELECT @MinQM = cast(val AS INT)
					FROM dbo.strsplit(@MinQMArr, ',')
					WHERE rank = @i

					SELECT @MaxQM = cast(val AS INT)
					FROM dbo.strsplit(@MaxQMArr, ',')
					WHERE rank = @i

					SELECT @Commission = cast(val AS DECIMAL(9, 8))
					FROM dbo.strsplit(@CommissionArr, '@')
					WHERE rank = @i

					/*Kiem tra du lieu la hop le :   
                + cac gia tri khong nho hon 0   
                + min < max  
                + min sau = max truoc + 1 (@i>1)  
                + Commission sau > Commission truoc va khong duoc lon hon 1  
                + Neu la tier cuoi cung thi hai gia tri max phai la vo cuc  
                + Cac gia tri min, max khong duoc lon hon vo cuc  
                + Vo Cuc(MaxAmount)= 100000000000000  
                + Vo Cuc(MaxQM) =1000000000   
         
       */
					IF (
							@MinAmount >= 0
							AND @MaxAmount <= 100000000000000
							AND @MinAmount <= @MaxAmount
							AND @MinQM >= 0
							AND @MaxQM <= 1000000000
							AND @MinQM <= @MaxQM
							AND (
								@Commission BETWEEN 0
									AND 1
								)
							AND (CASE 
								WHEN (
										@i = 1
										AND @i < @NTier
										) THEN 1
								WHEN (
										@NTier > 1
										AND @i = @NTier
										AND @MaxQM = 1000000000
										AND @MaxAmount = 100000000000000
										AND @MinAmount = @PreMaxAmount + 1
										AND @MinQM = @PreMaxQM + 1
										AND @Commission >= @PreCommission
										) THEN 1
								WHEN (
										@NTier = 1
										AND @i = @NTier
										AND @MaxQM = 1000000000
										AND @MaxAmount = 100000000000000
										AND @MinQM = 0
										AND @MinAmount = 0
										) THEN 1
								WHEN (
										@i > 1
										AND @i < @NTier
										AND @MinAmount = @PreMaxAmount + 1
										AND @MinQM = @PreMaxQM + 1
										AND @Commission >= @PreCommission
										) THEN 1

								ELSE 0 END
								) = 1
							)
					BEGIN
						--Insert du lieu   
						INSERT INTO @GroupSetting (
							GroupID
							,ProductID
							,TierID
							,MinAmount
							,MaxAmount
							,MinQM
							,MaxQM
							,Commission
							)
						VALUES (
							@GroupID
							,@ProductID
							,@i
							,@MinAmount
							,@MaxAmount
							,@MinQM
							,@MaxQM
							,@Commission
							)

						--Neu khong dong nao duoc insert thi thoat <=> @@ROWCOUNT<>1   
						IF (@@ROWCOUNT <> 1)
						BEGIN
							SELECT @ErrCode = 40 --There was an error when inserting tier setting.

							RETURN
						END
					END
					ELSE
					BEGIN
						SELECT @ErrCode = 41 --Error! Invalid Setting Data

						RETURN
					END

					--Increase @i by 1   
					SELECT @i = @i + 1
				END --end inner while  

				SELECT @rank = min(rank)
				FROM dbo.strsplit(@ProductIDList, ';')
				WHERE rank > @rank
			END TRY

			BEGIN CATCH
				SELECT @ErrMsg = ERROR_MESSAGE()
					,@ErrCode = 10034

				RETURN
			END CATCH
		END --end outer while  
	END --end if  
	ELSE ---Invalid Setting Data  
	BEGIN
		SELECT @ErrCode = 42 -- Error! Invalid Setting Data (ProductIDList) !

		RETURN
	END

	--Checking again  
	IF NOT EXISTS (SELECT 1 FROM @GroupSetting)
	BEGIN
		SELECT @ErrCode = 41

		RETURN
	END

	--BEGIN TRANSACTION AFTER CHECKING VALID INPUT DATA  
	BEGIN TRANSACTION

	UPDATE cg
	SET cg.GroupName 			= @GroupName
		,cg.Description 		= @Description
		,cg.Currency 			= @Currency
		,cg.QualifiedAmount 	= @QualifiedAmount
		,cg.DepositPercent 		= @DepositPercent
		,cg.WithdrawalPercent	= @WithdrawalPercent
	FROM dbo.CommGroup cg WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.Exchange ex WITH(NOLOCK) ON cg.Currency = ex.ExchangeID
	WHERE cg.GroupID = @GroupID
	

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 43 --There was an error when updating data.Please try again!

		RETURN
	END

	DELETE dbo.DeductionSetting
	WHERE GroupID = @GroupID

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 43

		RETURN
	END

	INSERT INTO dbo.DeductionSetting (GroupID, DeductionID, DeductedPercentage)
	SELECT GroupID, DeductionID, DeductedPercentage
	FROM @DeductionSetting

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 43

		RETURN
	END

	DELETE GroupSetting
	WHERE GroupID = @GroupID

	IF (@@ERROR <> 0)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT 43

		RETURN
	END

	INSERT INTO dbo.GroupSetting (
		GroupID
		,ProductID
		,TierID
		,MinAmount
		,MaxAmount
		,MinQM
		,MaxQM
		,Commission
		)
	SELECT GroupID
		,ProductID
		,TierID
		,MinAmount
		,MaxAmount
		,MinQM
		,MaxQM
		,Commission
	FROM @GroupSetting

	IF @@ERROR <> 0 OR @@ROWCOUNT <> (SELECT COUNT(1) FROM @GroupSetting)
	BEGIN
		ROLLBACK TRANSACTION

		SELECT 43

		RETURN
	END

	DECLARE @SportsBookID TINYINT

	SELECT @SportsBookID = dbo.Aff_GetSportID('SportsBook')

	--Update MemberDaily PSP, Marketting fee,...
	UPDATE m
	SET PSP = (ABS(Deposit) * @DepositPercent) + (Withdrawal * @WithdrawalPercent)
		,Marketing = ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing', NULL), 0)
		,MemOddsFee = ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee', NULL), 0)
		,MemPLayTechFee = ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL), 0)
		,MemWinlostFake = - (- Winlost - ((ABS(Deposit) * @DepositPercent + Withdrawal * @WithdrawalPercent)) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, @SportsBookID, 'PSP', NULL), 0) - ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Marketing', NULL), 0) - ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'Odds Fee', NULL), 0) - ABS(Winlost) * ISNULL(dbo.Aff_GetDeductionPercent(m.AffID, ProductId, 'PlayTech Royalties', NULL), 0))
	FROM dbo.MemberDaily m WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON m.AffId = ai.AffId
	WHERE DATEDIFF(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ai.GroupId = @GroupId

	SELECT m.[AffID]
		,m.[Currency] AS [MemCurrency]
		,m.[WinlostDate]
		,m.[ProductID]
		,m.[SysExRate]
		,m.AffExRate
		,SUM(Marketing) AS MemMarketing
		,SUM(PSP) AS MemPSP
		,SUM(MemWinlostFake) AS MemWinlostFake
		,SUM(MemOddsFee) AS MemOddsFee
		,SUM(MemPLayTechFee) AS MemPLayTechFee
	INTO #MemberDailySum
	FROM dbo.MemberDaily(NOLOCK) AS m
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON m.AffId = ai.AffId
	WHERE DATEDIFF(m, m.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ai.GroupId = @GroupId
	GROUP BY m.AffID
		,m.Currency
		,m.Winlostdate
		,m.ProductID
		,m.[SysExRate]
		,m.[AffExRate]

	--Update AffDaily
	UPDATE ad
	SET ad.MemMarketing = md.MemMarketing
		,ad.MemPSP = md.MemPSP
		,ad.MemOddsFee = md.MemOddsFee
		,ad.MemPLayTechFee = md.MemPlayTechFee
	FROM dbo.AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN #MemberDailySum md(NOLOCK) ON ad.AffID = md.AffId
		AND ad.MemCurrency = md.MemCurrency
		AND ad.Winlostdate = md.Winlostdate
		AND ad.ProductID = md.ProductID

	UPDATE ad
	SET HouseNetWinLost = HouseWinLost - ISNULL(MemPSP, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - ISNULL(MemBonus, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - ISNULL(MemAdjustment, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
	FROM dbo.AffDaily ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ad.AffId = ai.AffId
	WHERE DATEDIFF(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ai.GroupId = @GroupId

	--AffDailySummary
	UPDATE ad
	SET ad.MemMarketing 		= tmp.MemMarketing
		,ad.MemMarketing_aff 	= tmp.MemMarketing_aff
		,ad.MemPSP 				= tmp.MemPSP
		,ad.MemPSP_aff 			= tmp.MemPSP_aff
		,ad.MemOddsFee 			= tmp.MemOddsFee
		,ad.MemOddsFee_aff 		= tmp.MemOddsFee_aff
		,ad.MemPLayTechFee 		= tmp.MemPlayTechFee
		,ad.MemPLayTechFee_aff 	= tmp.MemPlayTechFee_aff
	FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN (
		SELECT md.AffID
			,md.Winlostdate
			,md.ProductID
			,SUM(MemMarketing) * SysExRate AS MemMarketing
			,SUM(MemMarketing) * AffExRate AS MemMarketing_aff
			,SUM(MemPSP) * SysExRate AS MemPSP
			,SUM(MemPSP) * AffExRate AS MemPSP_aff
			,SUM(MemOddsFee) * SysExRate AS MemOddsFee
			,SUM(MemOddsFee) * AffExRate AS MemOddsFee_aff
			,SUM(MemPlayTechFee) * SysExRate AS MemPlayTechFee
			,SUM(MemPlayTechFee) * AffExRate AS MemPlayTechFee_aff
		FROM #MemberDailySum md(NOLOCK)
		GROUP BY md.AffID
			,md.Winlostdate
			,md.SysExRate
			,md.AffExRate
			,md.ProductID
		) tmp ON tmp.AffID = ad.AffID
		AND tmp.Winlostdate = ad.Winlostdate
		AND tmp.ProductID = ad.ProductID

	UPDATE ad
	SET HouseNetWinLost = HouseWinLost - ISNULL(MemPSP, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - ISNULL(MemBonus, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - ISNULL(MemAdjustment, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - ABS(ISNULL(MemWinlost, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
		,HouseNetWinLost_aff = HouseWinLost_aff - ISNULL(MemPSP_aff, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PSP', Winlostdate), 0)) - ISNULL(MemBonus_aff, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Bonus', Winlostdate), 0)) - ISNULL(MemAdjustment_aff, 0) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Adjustment', Winlostdate), 0)) - ABS(ISNULL(MemWinlost_aff, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Marketing', Winlostdate), 0)) - ABS(ISNULL(MemWinlost_aff, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'Odds Fee', Winlostdate), 0)) - ABS(ISNULL(MemWinlost_aff, 0)) * (1 - ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ProductID, 'PlayTech Royalties', Winlostdate), 0))
	FROM dbo.AffDailySummary ad WITH (ROWLOCK, UPDLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ad.AffId = ai.AffId
	WHERE DATEDIFF(m, ad.WinlostDate, CURRENT_TIMESTAMP) = 0
		AND ai.GroupId = @GroupId

	DROP TABLE #MemberDailySum;

	COMMIT TRANSACTION

	--Write the log   
	DECLARE @LogData NVARCHAR(MAX), @AffID INT, @SPName VARCHAR(100)

	IF (@GroupID > 1000)
		SELECT @AffID = @GroupID
	ELSE
		SELECT @AffID = 0

	SELECT @LogData = N'Update a commission group.GroupID=' + dbo.Aff_ToString(@GroupID)
					+ '\n GroupName=' + @GroupName
					+ '\n Currency='+ dbo.Aff_ToString(@Currency)
					+ '\n QualifiedAmount=' + dbo.Aff_ToString(@QualifiedAmount)
					+ '\n Description=' + @Description
					+ '\n ProductIDList=' + @ProductIDList
					+ '\n DeductionList=' + @DeductionList
					+ '\n DeductedPercentageList=' + @DeductedPercentageList
					+ '\n TierList=' + @TierList
					+ '\n MinAmountList=' + @MinAmountList
					+ '\n MaxAmountList=' + @MaxAmountList
					+ '\n MinQMList=' + @MinQMList
					+ '\n MaxQMList=' + @MaxQMList
					+ '\n CommissionList=' + @CommissionList

	SELECT @SPName = OBJECT_NAME(@@PROCID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'CommissionGroup'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @LogData
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupUpd] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupUpd] TO [vnteam] AS [dbo]
GO