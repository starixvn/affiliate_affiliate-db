ALTER PROCEDURE [dbo].[AffAdmin_MemberDel] 
	@LicenseeID	INT
	,@Username VARCHAR(30)
	,@UserID INT
	,@IP VARCHAR(20)
	,@RefNo BIGINT = 0 OUTPUT
	,@ErrCode INT = 0 OUTPUT
	,@ErrMsg VARCHAR(100) = '' OUTPUT
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
	- 20140429@Bobby.Nguyen: Re-arrange try..catch code to specify error code
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
Param's Explanation:  
	.@IP: ip of computer sent,  
	• @ErrCode:  
	= 0: Transaction recorded successfully.  
	> 0: Insert unsuccessful.  
	• @ErrMsg: Error description.  
*/
BEGIN
	SET NOCOUNT ON;

	--Check permission-----------------------------  
				EXEC [dbo].[Aff_Con_CheckPermission] @LicenseeID = @LicenseeID
		,@custid = @UserID
		,@funcname = '[Affiliate]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT;

	IF (@ErrCode <> 0)
	BEGIN
		SELECT @ErrCode = 101
			,@ErrMsg = 'You dont have permission.';

		RETURN;
	END

	--Check IBCCustID -----------------------------
	DECLARE @AffID INT

	SELECT @AffId = ai.AffId
	FROM dbo.MemberInfo mi WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK)
		ON mi.AffID = ai.AffID
	WHERE mi.UserName = @UserName
		AND mi.IsRemoved = 0

	IF (@AffID IS NULL)
	BEGIN
		SELECT @ErrCode = 102
			,@ErrMsg = 'There is not existing affiliate user.';

		RETURN;
	END

	DECLARE @FirstDayOfTheMonth DATETIME
		,@FirstDayOfPreviuosMonth DATETIME;

	SELECT @FirstDayOfTheMonth = dbo.Aff_GetFirstDayOfMonth(GETDATE())
		,@FirstDayOfPreviuosMonth = DATEADD(M, 1, @FirstDayOfTheMonth);

	BEGIN TRY
		UPDATE dbo.MemberInfo WITH (ROWLOCK, UPDLOCK)
		SET IsRemoved = 1
		WHERE UserName = @UserName
			AND AffId = @AffId;

		IF (
				EXISTS (
					SELECT TOP (1) 1
					FROM dbo.MemberDaily
					WHERE UserName = @UserName
						AND winlostdate >= @FirstDayOfTheMonth
						AND winlostdate < @FirstDayOfPreviuosMonth
					)
				)
		BEGIN
			--clone table MemberDailyRemoved to #tmpMemberRemoval
			SELECT TOP (0) md.*
			INTO #tmpMemberRemoval
			FROM dbo.MemberDailyRemoved md WITH (NOLOCK);

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
			INTO #tmpMemberRemoval([UserName], [WinlostDate], [ProductID], [AffID], [IBCCustID], [Currency], [AffCurrency], [AffExRate], [SysCurrency], [SysExRate], [Deposit], [Withdrawal], [Bonus], [Adjustment], [Turnover], [Outstanding], [Winlost], [DrawGame], [PSP], [Marketing], [MemWinlostFake], [MemOddsFee], [MemPLayTechFee], [AffTransfer], [Transfer3rd], [BetCount], [PlayerComm], [TurnoverNoDraw], [BetCountNoDraw], [TurnoverDraw])
			WHERE UserName = @UserName
				AND AffId = @AffId
				AND winlostdate >= @FirstDayOfTheMonth
				AND winlostdate < @FirstDayOfPreviuosMonth

			--re-calculate AffDaily & AffDailySummary
			BEGIN TRY
				EXEC dbo.Task_Aff_ReCalculateAffSumData @AffID = @AffId
					,@FromDate = @FirstDayOfTheMonth
					,@ToDate = @FirstDayOfPreviuosMonth
			END TRY

			BEGIN CATCH
				SELECT @ErrCode = 104
					,@ErrMsg = 'Sum data process failed.'

				RETURN;
			END CATCH

			--insert into MemberDailyRemoved --------------
			INSERT INTO dbo.MemberDailyRemoved
			SELECT *
			FROM #tmpMemberRemoval;

			DROP TABLE #tmpMemberRemoval;
		END

		--insert new to MemberRemoval -----------------
		INSERT INTO dbo.MemberRemoval (
			UserName
			,RemovedDate
			,RemovedBy
			,AffID
			)
		VALUES (
			@UserName
			,GETDATE()
			,@UserID
			,@AffID
			);

		--update TotalMembers for this affiliate ------
		UPDATE dbo.AffInfo WITH (ROWLOCK, UPDLOCK)
		SET TotalMembers = TotalMembers - 1
		WHERE AffID = @AffID
	END TRY

	BEGIN CATCH
		SELECT @ErrCode = 103
			,@ErrMsg = 'Remove member failed.'

		RETURN;
	END CATCH

	--Write the log -----------------------------
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100);

	SELECT @SPName = OBJECT_NAME(@@ProcID)
		,@LogData = 'Remove member. UserName=' + dbo.Aff_ToString(@UserName);

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserID
		,@AffID = @AffID
		,@Typename = 'Member'
		,@SPName = @SPName
		,@RefNo = '00000'
		,@IP = @IP
		,@Details = @LogData
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_MemberDel] TO [bodbAdminNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_MemberDel] TO [vnteam] AS [dbo]