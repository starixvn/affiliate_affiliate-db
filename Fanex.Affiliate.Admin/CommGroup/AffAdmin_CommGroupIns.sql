ALTER PROCEDURE [dbo].[AffAdmin_CommGroupIns] 
	@LicenseeID					INT
	,@UserId 					INT
	,@Currency 					INT
	,@QualifiedAmount 			MONEY
	,@GroupName 				NVARCHAR(100)
	,@Description 				NVARCHAR(100) 	= NULL
	,@ProductIDList 			VARCHAR(300)
	,@DeductionList 			VARCHAR(300) 	= NULL
	,@DeductedPercentageList 	VARCHAR(300) 	= NULL
	,@TierList 					VARCHAR(300)
	,@MinAmountList 			VARCHAR(5000)
	,@MaxAmountList 			VARCHAR(5000)
	,@MinQMList 				VARCHAR(5000)
	,@MaxQMList 				VARCHAR(5000)
	,@CommissionList 			VARCHAR(5000)
	,@Language 					VARCHAR(5) 		= NULL
	,@IP 						VARCHAR(20)
	,@DepositPercent			FLOAT			= NULL
	,@WithdrawalPercent			FLOAT			= NULL
	,@GroupId 					INT 			= - 1 OUTPUT
	,@ErrCode 					INT 			= 0 OUTPUT
	,@ErrMsg 					NVARCHAR(4000) 	= '' OUTPUT
AS
/*  
Created: 20090719@DungTong  
Task : Add a new Commission Group  
DB: DB052.Affiliate_ZZun  
Original:  
  
Revisions:  
	- 20130924@Joseph: new version
	- 20131105@Johnny: Check currency permission
	- 20140724@Bobby: Update generating @GroupId
	- 20140820@Bobby: Add Deposit & Withdrawal percent and apply SQL stylescope
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
Parameters:  
.@UserID : Administrator user id  
.@GroupID : if @GroupID=-1 (normal group)  
            if @GroupID>1000 ==> Special Setting for Affiliate that has AffID=@GroupID  
 .@GroupName The name of this Group  
 .@Description : description for this group  
 .@ProductIDList: list of ProductID separated by semi colon  
                1 : SportsBook  
                2 : Casino  
                Ex: 1;2        
 .@DeductionList: List of Deduction Setting for above Sport List.                     
                  each deduction separated by a comma                    
                  1 : HasPSP  
                  2 : HasBonus  
                  3 : Has Adjustment  
                  4 : Has Marketing  
                  5 : Has Bonus for Casino  
                  6 : Has Adjustment for Casino  
                 Ex: 1,2,3,5,6  
                 Mean: SportsBook has deduction setting: HasPSP,HasBonus,Has Adjusment  
                      Casino has deduction setting: Has Bonus for Casino, Has Adjustment for Casino  
  .@DeductedPercentageList : List of Deducted Percentage  
              Ex: 1,0.05,1,0.17,1                                     
  . @TierList : List of number of Tiers for each sport type separated by a semi colon  
                each sport type separated by a semi colon  
                Ex: 3;4  
                Mean: SportsBook has 3 tiers  
                       Casino has 4 tiers  
   . @MinAmountList: List of MinAmount for each tier (all sports)  
                      each minAmount number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,1,100001;0,1,5001,700001  
    . @MaxAmountList: List of MaxAmount for each tier (all sports)  
                      each maxAmount number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,10000,100000000000000;0,5000,70000,100000000000000  
     . @MinQMList: List of MinQM for each tier (all sports)  
                      each minQM number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 0,10,20;0,5,10,21  
    . @MaxQMList: List of MaxQM for each tier (all sports)  
                      each maxQM number separated by a comma  
                      for each sport type separated by a semi colon  
                  Ex: 9,19,1000000000;4,9,20,1000000000  
     . @CommissionList: List of Commission for each tier (all sports)  
                         each commission number separated by a @  
                      for each sport type separated by a semi colon  
                  Ex: 0.00@0.20@0.35;0.00@0.10@0.15@0.20       
     .@IP : IP of admin user               
     .@ErrCode:    
                  0 : no error raised  
                  >0 : there was an error  
     .@ErrMsg :     
                  empty: no error raised  
                  others : the error message detail                            
                            
*/
BEGIN
	SET NOCOUNT ON;

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
	EXEC [dbo].[AffAdmin_CheckPermissionCurrency] 
		@LicenseeID = @LicenseeID
		,@UserId = @UserID
		,@CurrencyId = @Currency
		,@ErrCode = @ErrCode OUTPUT

	IF (@ErrCode <> 0) RETURN

	IF (
			@GroupName IS NULL
			OR LTRIM(RTRIM(@GroupName)) = ''
			)
	BEGIN
		SELECT @ErrCode = 20 --Group name is empty. Please choose a name!

		RETURN
	END

	IF (
			EXISTS (
				SELECT TOP 1 1
				FROM CommGroup WITH (NOLOCK)
				WHERE GroupName = @GroupName
					AND IsDeleted = 0
				)
			)
	BEGIN
		SELECT @ErrCode = 21 --Group name existed. Please choose another name!

		RETURN
	END

	--Check Qualified Amount  
	IF (@QualifiedAmount < 0)
	BEGIN
		SELECT @ErrCode = 22 --Invalid qualified amount. Please check.

		RETURN
	END

	SELECT @GroupID = ISNULL(MAX(GroupID), 0) + 1
	FROM dbo.CommGroup WITH (NOLOCK)

	IF (@GroupID <= 0)
	BEGIN
		SELECT @ErrCode = 23 --There is no room for a new Group! Please contact to administrator.

		RETURN
	END

	-- Check for inserting Deposit & Withdrawal percent
	SELECT @DepositPercent 		= ISNULL(@DepositPercent, ex.DepositPercent)
		,@WithdrawalPercent		= ISNULL(@WithdrawalPercent, ex.WithdrawalPercent)
	FROM dbo.Exchange ex WITH(NOLOCK)
	WHERE ex.ExchangeId = @Currency
	
	BEGIN TRANSACTION

	INSERT INTO CommGroup (
		[GroupID]
		,[GroupName]
		,[CreatedDate]
		,[Creator]
		,[IsDeleted]
		,[Description]
		,QualifiedAmount
		,Currency
		,DepositPercent
		,WithdrawalPercent
		)
	VALUES (
		@GroupID
		,@GroupName
		,current_timestamp
		,@UserId
		,0
		,@Description
		,@QualifiedAmount
		,@Currency
		,@DepositPercent
		,@WithdrawalPercent
		)

	IF @@ERROR <> 0
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 24 --Error occurs. Insert unsuccessfully.

		RETURN
	END

	--Insert Deduction Setting  
	IF (@DeductionList IS NOT NULL)
	BEGIN
		INSERT INTO DeductionSetting (
			GroupID
			,DeductionID
			,DeductedPercentage
			)
		SELECT @GroupID
			,cast(t.val AS TINYINT)
			,cast(p.val AS FLOAT)
		FROM dbo.strsplit(@DeductionList, ',') t
			INNER JOIN dbo.strsplit(@DeductedPercentageList, ',') p ON p.rank = t.rank
			INNER JOIN DeductionType d WITH (NOLOCK) ON d.DTypeID = cast(t.val AS TINYINT)

		IF @@Rowcount <> (
				SELECT count(1)
				FROM dbo.strsplit(@DeductionList, ',')
				)
			OR @@ERROR <> 0
		BEGIN
			ROLLBACK TRANSACTION

			SELECT @ErrCode = 25 --Error! Insert Deduction Setting unsuccessfully!

			RETURN
		END
	END

	--Insert Tier Setting  
	DECLARE @rank INT
		,@ProductID INT
		,@NTier INT
		,@i INT
		,@MinQM INT
		,@MaxQM INT
		,@PreMaxQM INT
	DECLARE @MinAmountArr VARCHAR(500)
		,@MaxAmountArr VARCHAR(500)
		,@MinQMArr VARCHAR(500)
		,@MaxQMArr VARCHAR(500)
		,@CommissionArr VARCHAR(500)
	DECLARE @MinAmount MONEY
		,@MaxAmount MONEY
		,@PreMaxAmount MONEY
	DECLARE @Commission DECIMAL(9, 8)
		,@PreCommission DECIMAL(9, 8)

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
					ROLLBACK TRANSACTION

					SELECT @ErrCode = 26 --Error! Invalid Tier List!

					RETURN
				END

				IF (@NTier > 50)
				BEGIN
					ROLLBACK TRANSACTION

					SELECT @ErrCode = 27 --Oops, maximum of 50 tiers are allowed!  

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
						INSERT INTO GroupSetting (
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

						--Neu khong dong nao duoc insert thi Rollback <=> @@ROWCOUNT<>1   
						IF (@@ROWCOUNT <> 1)
						BEGIN
							ROLLBACK TRANSACTION

							SELECT @ErrCode = 28 --There was an error when inserting tier setting.  

							RETURN
						END
					END
					ELSE
					BEGIN
						ROLLBACK TRANSACTION

						SELECT @ErrCode = 29
							,@ErrMsg = @ProductID --Error! Invalid Setting Data(ProductID=

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
				ROLLBACK TRANSACTION

				SELECT @ErrMsg = ERROR_MESSAGE()
					,@ErrCode = 9999

				RETURN
			END CATCH
		END --end outer while  
	END --end if  
	ELSE ---Invalid Setting Data  
	BEGIN
		ROLLBACK TRANSACTION

		SELECT @ErrCode = 30 --Error! Invalid Setting Data (ProductIDList) !

		RETURN
	END

	COMMIT TRANSACTION

	--Write the log   
	DECLARE @LogData NVARCHAR(4000)
		,@AffID INT
		,@SPName VARCHAR(100)

	SELECT @AffID = 0

	SELECT @LogData = N'Add a commission group.GroupID=' + dbo.Aff_ToString(@GroupID) + '\n GroupName=' + dbo.Aff_ToString(@GroupName) + '\n Currency' + dbo.Aff_ToString(@Currency) + '\n QualifiedAmount=' + dbo.Aff_ToString(@QualifiedAmount) + '\n Description=' + dbo.Aff_ToString(@Description) + '\n ProductIDList=' + dbo.Aff_ToString(@ProductIDList) + '\n DeductionList=' + dbo.Aff_ToString(@DeductionList) + '\n DeductedPercentageList=' + dbo.Aff_ToString(@DeductedPercentageList) + '\n TierList=' + dbo.Aff_ToString(@TierList) + '\n MinAmountList=' + dbo.Aff_ToString(@MinAmountList) + '\n MaxAmountList=' + dbo.Aff_ToString(@MaxAmountList) + '\n MinQMList=' + dbo.Aff_ToString(@MinQMList) + '\n MaxQMList=' + dbo.Aff_ToString(@MaxQMList) + '\n CommissionList=' + dbo.Aff_ToString(@CommissionList)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'CommissionGroup'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @LogData
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupIns] TO [bodbAdminNet] AS [dbo]
GO
