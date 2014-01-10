ALTER PROCEDURE [dbo].[AffAdmin_MemberDel]  
	@Username	VARCHAR(30),  
	@UserID		INT,   
	@IP			VARCHAR(20),    
	@RefNo		BIGINT = 0 OUTPUT,   
	@ErrCode	INT = 0 OUTPUT,  
	@ErrMsg		VARCHAR(100) = '' OUTPUT  
AS  
/*  
Created: 20090910@Peter  
Task : Remove a member from Affiliate  
DB: Affiliate DB  
Original: Affiliate_Athena000
  
Revisions:  
	- 20100413@Peter: Remove the calling to sp [DB02].[bodb02].[dbo].[Aff_MemberUpdAffID]  
					coz AffiliateID in custinfo will be removed.    
	- 20100512@Johnny: Re-calculate AffDaily if member is removed.  
	- 20100927@Peter : Add OddsFee column for AffDetail  
	- 20140110@Bobby.Nguyen: revise logical code
	
Param's Explanation:  
	.@IP: ip of computer sent,  
	• @ErrCode:  
	= 0: Transaction recorded successfully.  
	> 0: Insert unsuccessful.  
	• @ErrMsg: Error description.  
*/  
BEGIN
	SET NOCOUNT ON ;

	--Check permission-----------------------------  
	EXEC [dbo].[Aff_Con_CheckPermission] 
		@custid		= @UserID
		, @funcname = '[Affiliate]'  
		, @System	= 'AFFILIATE'  
		, @ErrCode	= @ErrCode OUTPUT;
   
	If (@ErrCode <> 0)	
	BEGIN
		SELECT @ErrCode = 101
				, @ErrMsg = 'You dont have permission.';
		RETURN;
	END

	--Check IBCCustID -----------------------------
	DECLARE @AffID INT

	SELECT @AffId = ai.AffId 
	FROM dbo.MemberInfo mi WITH(NOLOCK) 
	INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON mi.AffID = ai.AffID
	WHERE mi.UserName = @UserName 
		AND mi.IsRemoved = 0  

	IF(@AffID IS NULL)  
	BEGIN  
		SELECT @ErrCode = 102
				, @ErrMsg = 'There is not existing affiliate user.';
		RETURN; 
	END
  
	DECLARE @FirstDayOfTheMonth DATETIME  
		, @FirstDayOfPreviuosMonth DATETIME;
	SELECT @FirstDayOfTheMonth = dbo.Aff_GetFirstDayOfMonth(GETDATE())
		, @FirstDayOfPreviuosMonth = DATEADD(M, 1, @FirstDayOfTheMonth);  

	BEGIN TRY  
		UPDATE dbo.MemberInfo WITH (ROWLOCK,UPDLOCK)
		SET IsRemoved = 1
		WHERE UserName = @UserName 
			AND AffId = @AffId;
	
		IF(EXISTS(SELECT TOP(1) 1 
					FROM dbo.MemberDaily 
					WHERE UserName = @UserName 
						AND winlostdate >= @FirstDayOfTheMonth 
						AND winlostdate < @FirstDayOfPreviuosMonth))
		BEGIN
			--clone table MemberDailyRemoved to #tmpMemberRemoval
			SELECT TOP(0) md.* 
			INTO #tmpMemberRemoval
			FROM dbo.MemberDailyRemoved md WITH(NOLOCK);

			--delete MemberDaily ------------------------- 
			DELETE 
			FROM dbo.MemberDaily
			OUTPUT DELETED.[UserName]
				,DELETED.[WinlostDate]
				,DELETED.[ProductID]
				,DELETED.[AffID]
				,DELETED.[IBCCustID]
				,DELETED.[Currency]
				,DELETED.[AffCurrency]
				,DELETED.[AffExRate]
				,DELETED.[SysCurrency]
				,DELETED.[SysExRate]
				,DELETED.[Deposit]
				,DELETED.[Withdrawal]
				,DELETED.[Bonus]
				,DELETED.[Adjustment]
				,DELETED.[Turnover]
				,DELETED.[Outstanding]
				,DELETED.[Winlost]
				,DELETED.[DrawGame]
				,DELETED.[PSP]
				,DELETED.[Marketing]
				,DELETED.[MemWinlostFake]
				,DELETED.[MemOddsFee]
				,DELETED.[MemPLayTechFee]
				,DELETED.[AffTransfer]
				,DELETED.[Transfer3rd]
				,DELETED.[BetCount]
				,DELETED.[PlayerComm]
				,DELETED.[TurnoverNoDraw]
				,DELETED.[BetCountNoDraw]
				,DELETED.[TurnoverDraw]
			INTO #tmpMemberRemoval (
				[UserName]
				,[WinlostDate]
				,[ProductID]
				,[AffID]
				,[IBCCustID]
				,[Currency]
				,[AffCurrency]
				,[AffExRate]
				,[SysCurrency]
				,[SysExRate]
				,[Deposit]
				,[Withdrawal]
				,[Bonus]
				,[Adjustment]
				,[Turnover]
				,[Outstanding]
				,[Winlost]
				,[DrawGame]
				,[PSP]
				,[Marketing]
				,[MemWinlostFake]
				,[MemOddsFee]
				,[MemPLayTechFee]
				,[AffTransfer]
				,[Transfer3rd]
				,[BetCount]
				,[PlayerComm]
				,[TurnoverNoDraw]
				,[BetCountNoDraw]
				,[TurnoverDraw])
			WHERE UserName = @UserName 
				AND winlostdate >= @FirstDayOfTheMonth AND winlostdate < @FirstDayOfPreviuosMonth

			--convert to AffDailySummary -------------------
			;WITH tmpMemberSum AS (
				SELECT AffID
					,Winlostdate
					,ProductID
					,Currency AS MemCurrency
					,AffCurrency
					,AffExRate
					,SysCurrency
					,SysExRate
					,SUM(ISNULL(Deposit, 0)) AS MemDeposit
					,SUM(ISNULL(Withdrawal, 0)) AS MemWithdrawal
					,SUM(ISNULL(Turnover, 0)) AS MemTurnover
					,SUM(ISNULL(Bonus, 0)) AS MemBonus
					,SUM(ISNULL(Adjustment, 0)) AS MemAdjustment
					,SUM(ISNULL(Marketing, 0)) AS MemMarketing	
					,SUM(ISNULL(PSP, 0)) AS MemPSP
					,SUM(ISNULL(Winlost, 0)) AS MemWinlost
					,-SUM(ISNULL(Winlost, 0))  AS HouseWinlost
					,SUM(ISNULL(MemWinlostFake, 0)) AS MemWinlostFake
					,SUM(ISNULL(MemOddsFee, 0)) AS MemOddsFee          		   
					,SUM(ISNULL(MemPLayTechFee, 0)) AS MemPLayTechFee
					,SUM(ISNULL(AffTransfer, 0)) AS MemAffTransfer
					,SUM(ISNULL(Transfer3rd, 0)) AS MemTransfer3rd
					,SUM(ISNULL(BetCount, 0)) AS MemBetCount
					,SUM(ISNULL(PlayerComm, 0)) AS MemPlayerComm
					,SUM(CASE WHEN turnover > 0 THEN 1 ELSE 0 END) AS ActivePlayer
					,SUM(ISNULL(TurnoverNoDraw, 0)) AS MemTurnoverNoDraw
					,SUM(ISNULL(BetCountNoDraw, 0)) AS MemBetCountNoDraw
					,SUM(ISNULL(TurnoverDraw, 0)) AS MemTurnoverDraw
				FROM #tmpMemberRemoval
				GROUP BY AffID
					,Winlostdate
					,ProductID
					,Currency
					,AffCurrency
					,AffExRate
					,SysCurrency
					,SysExRate
			) 
			UPDATE ad
				SET MemDeposit			= ad.MemDeposit - tmp.MemDeposit
					, MemWithdrawal		= ad.MemWithdrawal - tmp.MemWithdrawal
					, MemTurnover		= ad.MemTurnover - tmp.MemTurnover
					, MemBonus			= ad.MemBonus - tmp.MemBonus
					, MemAdjustment		= ad.MemAdjustment - tmp.MemAdjustment
					, MemMarketing		= ad.MemMarketing - tmp.MemMarketing
					, MemPSP			= ad.MemPSP - tmp.MemPSP
					, MemWinlost		= ad.MemWinlost - tmp.MemWinlost
					, HouseWinlost		= ad.HouseWinlost + tmp.HouseWinlost --negative balance
					, MemWinlostFake	= ad.MemWinlostFake - tmp.MemWinlostFake
					, MemOddsFee		= ad.MemOddsFee - tmp.MemOddsFee
					, MemPLayTechFee	= ad.MemPLayTechFee - tmp.MemPLayTechFee
					, MemAffTransfer	= ad.MemAffTransfer - tmp.MemAffTransfer
					, MemTransfer3rd	= ad.MemTransfer3rd - tmp.MemTransfer3rd
					, MemBetCount		= ad.MemBetCount - tmp.MemBetCount
					, MemPlayerComm		= ad.MemPlayerComm - tmp.MemPlayerComm
					, ActivePlayer		= ad.ActivePlayer - tmp.ActivePlayer
					, MemTurnoverNoDraw	= ad.MemTurnoverNoDraw - tmp.MemTurnoverNoDraw
					, MemBetCountNoDraw	= ad.MemBetCountNoDraw - tmp.MemBetCountNoDraw
					, MemTurnoverDraw	= ad.MemTurnoverDraw - tmp.MemTurnoverDraw
					, HouseNetWinLost	= ad.HouseNetWinLost - ((ad.HouseWinlost + tmp.HouseWinlost) 
																- ((ISNULL(ad.MemBonus, 0) - tmp.MemBonus) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ad.ProductID,'Bonus', ad.Winlostdate),0))
																- (ISNULL(ad.MemAdjustment,0)-tmp.MemAdjustment)  
																- ((ISNULL(ad.MemPSP,0) - tmp.MemPSP) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ad.ProductID,'PSP', ad.Winlostdate),0)) 
																- (ABS(ISNULL(ad.MemWinlost,0) - tmp.MemWinlost) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ad.ProductID,'Marketing', ad.Winlostdate),0))
																- (ABS(ISNULL(ad.MemWinlost,0) - tmp.MemWinlost) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ad.ProductID,'Odds Fee',ad.Winlostdate),0))
																- (ABS(ISNULL(ad.MemWinlost,0) - tmp.MemWinlost) * ISNULL(dbo.Aff_GetDeductionPercent(ad.AffID, ad.ProductID,'PlayTech Royalties', ad.Winlostdate),0))  
															)
			FROM dbo.AffDaily ad WITH(ROWLOCK,UPDLOCK)
			INNER JOIN tmpMemberSum tmp 
				ON ad.AffID = tmp.AffID 
					AND ad.winlostdate	= tmp.winlostdate 
					AND ad.MemCurrency	= tmp.MemCurrency;

			--update AffDailySummary -----------------------
			;WITH tmpAffSumm AS 
			(
				SELECT [AffID]  
					,[Winlostdate]  
					,[ProductID]
					,[AffCurrency]
					,[SysCurrency]  
					,SUM([MemDeposit] * SysExRate) AS [MemDeposit]
					,SUM([MemWithdrawal] * SysExRate) AS [MemWithdrawal]
					,SUM([MemTurnover] * SysExRate) AS [MemTurnover]
					,SUM([MemBonus] * SysExRate) AS   [MemBonus]
					,SUM([MemAdjustment] * SysExRate) AS   [MemAdjustment]
					,SUM([MemMarketing] * SysExRate) AS  [MemMarketing] 
					,SUM([MemPSP] * SysExRate) AS   [MemPSP]
					,SUM([MemWinlost] * SysExRate) AS   [MemWinlost]
					,SUM([AffWinlost] * SysExRate) AS [AffWinlost]  
					,-SUM([MemWinlost] * SysExRate) AS  [HouseWinlost] --negative balance
					,0 AS  [AffNetWinlost] 
					,0 AS  [HouseNetWinlost] 
					,SUM([MemOddsFee] * SysExRate) AS   [MemOddsFee]
					,SUM([MemPLayTechFee] * SysExRate) AS [MemPLayTechFee]
					,0 AS [MemWinlostFake]
					,SUM([MemDeposit] * AffExRate) AS [MemDeposit_aff]
					,SUM([MemWithdrawal] * AffExRate) AS [MemWithdrawal_aff]
					,SUM([MemTurnover] * AffExRate) AS [MemTurnover_aff]
					,SUM([MemBonus] * AffExRate) AS [MemBonus_aff]
					,SUM([MemAdjustment] * AffExRate) AS [MemAdjustment_aff]
					,SUM([MemMarketing] * AffExRate) AS [MemMarketing_aff]
					,SUM([MemPSP] * AffExRate) AS [MemPSP_aff]
					,SUM([MemWinlost] * AffExRate) AS [MemWinlost_aff]
					,0 AS [AffWinlost_aff]
					,-SUM([MemWinlost] * AffExRate) AS [HouseWinlost_aff] --negative balance
					,0 AS [AffNetWinlost_aff]
					,0 AS [HouseNetWinlost_aff]
					,SUM([MemOddsFee] * AffExRate) AS [MemOddsFee_aff]
					,SUM([MemWinlostFake] * AffExRate) AS [MemWinlostFake_aff]
					,SUM([MemPLayTechFee] * AffExRate) AS [MemPLayTechFee_aff]
					,SUM(ISNULL([MemAffTransfer], 0) * SysExRate)  AS MemAffTransfer
					,SUM(ISNULL([MemTransfer3rd], 0) * SysExRate) AS MemTransfer3rd
					,SUM([MemBetCount]) AS MemBetCount
					,SUM([MemPlayerComm]* SysExRate) AS MemPlayerComm
					,SUM(ISNULL([MemAffTransfer], 0) * AffExRate) AS MemAffTransfer_aff
					,SUM(ISNULL([MemTransfer3rd], 0) * AffExRate) AS MemTransfer3rd_aff
					,SUM([MemPlayerComm]* AffExRate) AS MemPlayerComm_aff
					,SUM([MemTurnoverNoDraw]* SysExRate) AS MemTurnoverNoDraw
					,SUM([MemBetCountNoDraw]) AS MemBetCountNoDraw
					,SUM([MemTurnoverNoDraw]* AffExRate) AS MemTurnoverNoDraw_aff
					,SUM([MemTurnoverDraw]* SysExRate) AS MemTurnoverDraw
					,SUM([MemTurnoverDraw]* AffExRate) AS MemTurnoverDraw_aff

				FROM dbo.AffDaily WITH(NOLOCK)
				WHERE AffId = @AffId
					AND winlostdate >= @FirstDayOfTheMonth AND winlostdate < @FirstDayOfPreviuosMonth
				GROUP BY AffID
					, Winlostdate
					, ProductID
					, AffCurrency
					, SysCurrency
			) 
			UPDATE aff
				SET MemDeposit		= tmp.MemDeposit
				, MemWithdrawal		= tmp.MemWithdrawal
				, MemTurnover		= tmp.MemTurnover
				, MemBonus			= tmp.MemBonus
				, MemAdjustment		= tmp.MemAdjustment
				, MemMarketing		= tmp.MemMarketing
				, MemPSP			= tmp.MemPSP
				, MemWinlost		= tmp.MemWinlost
				, AffWinlost		= tmp.AffWinlost
				, HouseWinlost		= tmp.HouseWinlost 
				, AffNetWinlost		= tmp.AffNetWinlost
				, MemOddsFee		= tmp.MemOddsFee
				, MemPLayTechFee	= tmp.MemPLayTechFee
				, MemWinlostFake	= tmp.MemWinlostFake
				, MemDeposit_aff	= tmp.MemDeposit_aff
				, MemWithdrawal_aff	= tmp.MemWithdrawal_aff
				, MemTurnover_aff	= tmp.MemTurnover_aff
				, MemBonus_aff		= tmp.MemBonus_aff
				, MemAdjustment_aff	= tmp.MemAdjustment_aff
				, MemMarketing_aff	= tmp.MemMarketing_aff
				, MemPSP_aff		= tmp.MemPSP_aff
				, MemWinlost_aff	= tmp.MemWinlost_aff
				, AffWinlost_aff	= tmp.AffWinlost_aff
				, HouseWinlost_aff	= tmp.HouseWinlost_aff
				, AffNetWinlost_aff	= tmp.AffNetWinlost_aff
				, MemOddsFee_aff		= tmp.MemOddsFee_aff
				, MemWinlostFake_aff	= tmp.MemWinlostFake_aff
				, MemPLayTechFee_aff	= tmp.MemPLayTechFee_aff
				, MemAffTransfer		= tmp.MemAffTransfer
				, MemTransfer3rd		= tmp.MemTransfer3rd
				, MemBetCount			= tmp.MemBetCount
				, MemPlayerComm			= tmp.MemPlayerComm
				, MemAffTransfer_aff	= tmp.MemAffTransfer_aff
				, MemTransfer3rd_aff	= tmp.MemTransfer3rd_aff
				, MemPlayerComm_aff		= tmp.MemPlayerComm_aff
				, MemTurnoverNoDraw		= tmp.MemTurnoverNoDraw
				, MemBetCountNoDraw		= tmp.MemBetCountNoDraw
				, MemTurnoverNoDraw_aff	= tmp.MemTurnoverNoDraw_aff
				, MemTurnoverDraw		= tmp.MemTurnoverDraw
				, MemTurnoverDraw_aff	= tmp.MemTurnoverDraw_aff
				, HouseNetWinlost		= (-tmp.MemWinlost  
											-tmp.MemBonus * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'Bonus', aff.WinlostDate)  
											-tmp.MemAdjustment  
											-tmp.MemPSP * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID, 'PSP', aff.WinlostDate)  
											- ABS(tmp.MemWinlost) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID, 'Marketing', aff.WinlostDate)  
											- ABS(tmp.MemWinlost) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID, 'Odds Fee', aff.WinlostDate)  
											- ABS(tmp.MemWinlost) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID, 'PlayTech Royalties', aff.WinlostDate)  
										)
				, HouseNetWinlost_aff	= (-tmp.MemWinlost_aff  
											-tmp.MemBonus_aff * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'Bonus', aff.WinlostDate)  
											-tmp.MemAdjustment_aff  
											-tmp.MemPSP_aff * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'PSP', aff.WinlostDate)  
											- ABS(tmp.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'Marketing', aff.WinlostDate)  
											- ABS(tmp.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'Odds Fee', aff.WinlostDate)  
											- ABS(tmp.MemWinlost_aff) * dbo.Aff_GetDeductionPercent(aff.AffID, aff.ProductID,'PlayTech Royalties', aff.WinlostDate)  
										)   
			FROM dbo.AffDailySummary aff WITH (ROWLOCK,UPDLOCK)
			INNER JOIN tmpAffSumm tmp ON aff.AffID = tmp.AffID 
					AND aff.Winlostdate = tmp.Winlostdate
					AND aff.ProductID = tmp.ProductID
					AND aff.AffCurrency = tmp.AffCurrency
					AND aff.SysCurrency = tmp.SysCurrency;		

			--insert into MemberDailyRemoved --------------
			INSERT INTO dbo.MemberDailyRemoved
			SELECT * FROM #tmpMemberRemoval;

			--insert new to MemberRemoval -----------------
			INSERT INTO dbo.MemberRemoval(UserName
				, RemovedDate
				, RemovedBy
				, AffID
			)
			VALUES (@UserName
				, GETDATE()
				, @UserID
				, @AffID
			);

			--update TotalMembers for this affiliate ------
			UPDATE dbo.AffInfo WITH (ROWLOCK,UPDLOCK)
			SET TotalMembers = TotalMembers - 1
			WHERE AffID = @AffID

			DROP TABLE #tmpMemberRemoval;
		END

	END TRY  
	BEGIN CATCH
		SELECT @ErrCode = ERROR_NUMBER()
				, @ErrMsg = ERROR_MESSAGE()
		RETURN;
	END CATCH     
	--Write the log -----------------------------
	DECLARE @LogData NVARCHAR(4000)
		, @SPName VARCHAR(100);
	SELECT @SPName = OBJECT_NAME(@@ProcID)
		, @LogData = 'Remove member. UserName=' + dbo.Aff_ToString(@UserName) ;

	EXEC [dbo].[Aff_WriteLog]  
		@Creator	= @UserID,   
		@AffID		= @AffID,  
		@Typename	= 'Member',   
		@SPName		= @SPName ,  
		@RefNo		= '00000',  
		@IP			= @IP,  
		@Details	= @LogData         
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberDel] TO [bodbadminNet]