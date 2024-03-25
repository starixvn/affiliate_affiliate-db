/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_aff" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliateReport_Sel]
	@Username				NVARCHAR(50) = NULL
	,@FromDate				SMALLDATETIME
	,@ToDate				SMALLDATETIME
	,@PreferredLanguages	VARCHAR(MAX)
	,@ProductIds			VARCHAR(MAX) = '0'
	,@SortType				TINYINT = 1
	,@SortDirectionType		BIT = 0
	,@IsExportExcel			BIT = 0
	,@IsGetMonthly       	BIT = 1
	,@PageIndex				INT = 1
	,@PageSize				INT = 50
	,@NRows					INT = 0 OUTPUT
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin site - Report - Affiliate Report

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20181001@Percy: Support export excel [RedmineID: #102322]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20191101@Percy: Fix wrong FDM value [RedmineID: #123134]
		- 20200731@Percy: Change way to input Language [RedmineID: #121975]
		- 20210223@Percy: Do not show affiliate with all value is zero [149213]
		- 20210423@Malcolm: Fix Number of Affiliates in a page don't equal PageSize [RedmineId: #152957]
		- 20210528@Malcolm: Get data daily [RedmineID: #149210]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
		- 20230802@Eddie: 'ExchangeWinlossShare' and 'ExchangeCommShare' out of use [RedmineID: #189569]
		- 20240321@Eddie: Change Link Server and metadata "bodbAdminNet" [RedmineID: #202712]

	Param's Explanation:
		- @SortType: 1: Affiliate username, 2: Turnover, 3: Winloss, 4: Earning (Commission)
		- @SortDirectionType: 0: ASC (ascending), 1: DESC (descending)
		- @ProductIds: list of products
*/

BEGIN
	SET NOCOUNT ON

	IF @FromDate IS NULL OR @ToDate IS NULL
		RETURN

	SELECT  @Username = ISNULL(LTRIM(RTRIM(@Username)), ''), @PreferredLanguages = ISNULL(@PreferredLanguages, '')
	
	DECLARE @MinReportDate SMALLDATETIME, @EndOfCurrentMonth SMALLDATETIME, @NoOfMonth INT, @IsCalMonthly BIT = 0
	SELECT  @MinReportDate		= dbo.Aff_f_GetMinReportDate(0)
	SELECT  @EndOfCurrentMonth	= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()) + 1, 0))
	
	IF @IsGetMonthly = 1
	BEGIN
		SELECT  @FromDate 		= DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0) -- Begin Of Month
				,@ToDate  		= DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0)) -- End Of Month	        
		        ,@MinReportDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MinReportDate), 0)
	END
	

	IF @FromDate < @MinReportDate
		SELECT @FromDate = @MinReportDate

	IF @ToDate > @EndOfCurrentMonth
		SELECT @ToDate = @EndOfCurrentMonth

	SELECT @NoOfMonth = DATEDIFF(MONTH, @FromDate, @ToDate) + 1
	
	IF @NoOfMonth <= 0
		RETURN

	DECLARE @MonthDate TABLE (MonthDate SMALLDATETIME)
	;WITH CTE_MonthDate AS
	(
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)) AS MonthDate
		UNION ALL
		SELECT DATEADD(DAY, -1, DATEADD(MONTH, 1, DATEADD(DAY, 1, MonthDate)))
		FROM CTE_MonthDate
		WHERE MonthDate < @ToDate
	)
	INSERT INTO @MonthDate (MonthDate)
	SELECT MonthDate FROM CTE_MonthDate
	OPTION (MAXRECURSION 0)

	DECLARE @MaxCommDate SMALLDATETIME
	SELECT  @MaxCommDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

	DECLARE @threshold1 DATETIME, @threshold2 DATETIME, @tempFromDate DATETIME, @tempToDate DATETIME

	/*
		===== Get data =====
	*/

	DROP TABLE IF EXISTS #AffTrans
	DROP TABLE IF EXISTS #FDM
	DROP TABLE IF EXISTS #Result
	DROP TABLE IF EXISTS #Signup
	DROP TABLE IF EXISTS #Statistics
	DROP TABLE IF EXISTS #TempCommission

	BEGIN
		CREATE TABLE #TempCommission
		(
			MonthDate			SMALLDATETIME
			,AffId				INT
			,GroupId			INT
			,ProductId			INT
			,Deposit			MONEY
			,Withdrawal			MONEY
			,Bonus				MONEY
			,Turnover			MONEY
			,Winloss			MONEY
			,AWinloss			MONEY
			,AComm				MONEY
			-- Fees
			,PlatFormFee		MONEY
			,OperationalFee		MONEY
			,BankingFee			MONEY
			-- Calculation
			,GrossWinloss		MONEY
			,NetWinloss			MONEY
			,ActivePlayer		INT
			,QualifiedMember	INT
			,QMTurnover			MONEY
			,CommissionRate		FLOAT
			,Commission			MONEY
			-----FDM & Bonus
			,IsApplyBonus		BIT
			,FDMCount			INT
			,FDMDeposit			MONEY
			,FDMCommissionRate	DECIMAL(9, 8)
			,FDMCommission		MONEY
		)
		
		IF @FromDate <>  DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate), 0)
		BEGIN	
			SELECT @threshold1 = DATEADD(MONTH, DATEDIFF(MONTH, 0, @FromDate) + 1, 0)
		END
		ELSE
			SELECT @threshold1 = @FromDate
		
		IF @ToDate <> DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0))
		BEGIN
			SELECT @threshold2 = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate), 0))
			SELECT @threshold2 = CASE WHEN @threshold2 > @MaxCommDate THEN @MaxCommDate ELSE @threshold2 END
		END
		ELSE 
		BEGIN
			SELECT @threshold2 = CASE WHEN @ToDate > @MaxCommDate THEN @MaxCommDate ELSE @ToDate END
		END
		
		IF @threshold1 >= @threshold2 
		BEGIN
			INSERT INTO #TempCommission
			(
				MonthDate
				,AffId
				,GroupId
				,ProductId
				,Deposit
				,Withdrawal
				,Bonus
				,Turnover
				,Winloss
				,AWinloss
				,AComm
				,PlatFormFee
				,OperationalFee
				,BankingFee
				,GrossWinloss
				,NetWinloss
				,ActivePlayer
				,QualifiedMember
				,QMTurnOver
				,CommissionRate
				,Commission
				---FDM & Bonus
				,IsApplyBonus
				,FDMCount
				,FDMDeposit
				,FDMCommissionRate
				,FDMCommission
			)
			EXEC dbo.Aff_Commission_UnCalc
				@AffIds				= 'all'
				,@FromMonthDate		= @FromDate
				,@ToMonthDate		= @ToDate
				,@IsGetMonthly		= 0
				,@ProductIds		= @ProductIds
				,@IsSumAll			= 1
				,@GetRowTotalOnly	= 1
		END
		ELSE 
		BEGIN
			INSERT INTO #TempCommission
			(
				MonthDate
				,AffId
				,GroupId
				,ProductId
				,Deposit
				,Withdrawal
				,Bonus
				,Turnover
				,Winloss
				,AWinloss
				,AComm
				,PlatFormFee
				,OperationalFee
				,BankingFee
				,GrossWinloss
				,NetWinloss
				,ActivePlayer
				,QualifiedMember
				,QMTurnOver
				,CommissionRate
				,Commission
				---FDM & Bonus
				,IsApplyBonus
				,FDMCount
				,FDMDeposit
				,FDMCommissionRate
				,FDMCommission
			)
			EXEC dbo.Aff_Commission_Calc
				@AffIds				= 'all'
				,@FromMonthDate		= @threshold1
				,@ToMonthDate		= @threshold2
				,@ProductIds		= @ProductIds
				,@IsSumAll			= 1
				,@GetRowTotalOnly	= 1
			
			IF @FromDate <> @threshold1
			BEGIN
				SELECT @threshold1 = DATEADD(DAY, -1, @threshold1)

				INSERT INTO #TempCommission
				(
					MonthDate
					,AffId
					,GroupId
					,ProductId
					,Deposit
					,Withdrawal
					,Bonus
					,Turnover
					,Winloss
					,AWinloss
					,AComm
					,PlatFormFee
					,OperationalFee
					,BankingFee
					,GrossWinloss
					,NetWinloss
					,ActivePlayer
					,QualifiedMember
					,QMTurnOver
					,CommissionRate
					,Commission
					---FDM & Bonus
					,IsApplyBonus	
					,FDMCount	
					,FDMDeposit
					,FDMCommissionRate
					,FDMCommission
				)
				EXEC dbo.Aff_Commission_UnCalc
					@AffIds				= 'all'
					,@FromMonthDate		= @FromDate
					,@ToMonthDate		= @threshold1
					,@IsGetMonthly		= 0
					,@ProductIds		= @ProductIds
					,@IsSumAll			= 1
					,@GetRowTotalOnly	= 1
			 END
				
			 IF @ToDate <> @threshold2
			 BEGIN
				SELECT @threshold2 = DATEADD(DAY, 1, @threshold2)

				INSERT INTO #TempCommission
				(
					MonthDate
					,AffId
					,GroupId
					,ProductId
					,Deposit
					,Withdrawal
					,Bonus
					,Turnover
					,Winloss
					,AWinloss
					,AComm
					,PlatFormFee
					,OperationalFee
					,BankingFee
					,GrossWinloss
					,NetWinloss
					,ActivePlayer
					,QualifiedMember
					,QMTurnOver
					,CommissionRate
					,Commission
					---FDM & Bonus
					,IsApplyBonus
					,FDMCount
					,FDMDeposit
					,FDMCommissionRate
					,FDMCommission
				)
				EXEC dbo.Aff_Commission_UnCalc
					@AffIds				= 'all'
					,@FromMonthDate		= @threshold2
					,@ToMonthDate		= @ToDate
					,@IsGetMonthly		= 0
					,@ProductIds		= @ProductIds
					,@IsSumAll			= 1
					,@GetRowTotalOnly	= 1
			 END
		END	
		-- Signup
		CREATE TABLE #Signup (AffId INT, Signup INT)

		DECLARE @sql NVARCHAR(MAX)
		SELECT  @sql = 'SELECT a.AffId, a.Signup
						FROM OPENQUERY(DBDEPOSIT2, ''SELECT AffiliateId AS AffId, COUNT(1) AS Signup FROM Deposit_DB.dbo.v_Aff_DepCust WITH (NOLOCK)
													WHERE creatdate >= ''''' + CONVERT(VARCHAR(10), @FromDate, 120) + ''''' AND
														creatdate < ''''' + + CONVERT(VARCHAR(10), DATEADD(DAY, 1, @ToDate), 120) + '''''
													GROUP BY AffiliateId'') AS a'
		BEGIN TRY
			INSERT INTO #Signup (AffId, Signup)
			EXEC (@sql)
		END TRY
		BEGIN CATCH
		END CATCH

		-- Statistics
		CREATE TABLE #Statistics (AffId INT, TotalClick INT, UniqueClick INT, Signup INT, FDM INT)

		DECLARE @ArchiveDate SMALLDATETIME
		SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatistics1_bk WITH (NOLOCK)

		IF @ToDate > @ArchiveDate
		BEGIN
			SELECT @tempFromDate = CASE WHEN @FromDate <= @ArchiveDate THEN DATEADD(DAY, 1, @ArchiveDate) ELSE @FromDate END
			SELECT @tempToDate	= @ToDate

			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), SUM(UniqueClick)
			FROM 
			(
				SELECT
					AffId
					,DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate
					,COUNT(1) AS TotalClick
					,COUNT(DISTINCT IP) AS UniqueClick
				FROM dbo.ClickStatistics1 WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY AffId
						,DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
			) AS c
			GROUP BY AffId
		END

		IF @FromDate <= @ArchiveDate
		BEGIN
			SELECT @tempFromDate = @FromDate
			SELECT @tempToDate	= CASE WHEN @ToDate > @ArchiveDate THEN @ArchiveDate ELSE @ToDate END
			
			INSERT INTO #Statistics (AffId, TotalClick, UniqueClick)
			SELECT AffId, SUM(TotalClick), COUNT(1) AS UniqueClick
			FROM
			(
				SELECT
					AffId
					,DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0)) AS MonthDate
					,IP
					,COUNT(1) AS TotalClick
				FROM dbo.ClickStatistics1_bk WITH (NOLOCK)
				WHERE Date BETWEEN @tempFromDate AND @tempToDate
				GROUP BY AffId
						,DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, Date) + 1, 0))
						,IP
			) AS c
			GROUP BY AffId
		END

		-- FDM
		CREATE TABLE #FDM (AffId INT, FDM INT)
		INSERT INTO #FDM (AffId, FDM)
		SELECT mi.AffId, COUNT(1) AS FDM
		FROM dbo.MemberInfo mi WITH (NOLOCK)
		WHERE mi.CreatedDate >= @FromDate AND mi.CreatedDate < DATEADD(DAY, 1, @ToDate)
			AND NOT EXISTS (
				SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
				WHERE mi.IBCCustID = mr.IBCCustID
					AND mr.RemovedDate >= @FromDate AND mr.RemovedDate < DATEADD(DAY, 1, @ToDate)
			)
		GROUP BY mi.AffId
		
		-- AffWithdrawal, AffAdjustment
		CREATE TABLE #AffTrans (AffId INT, AffWithdrawal MONEY, AffAdjustment MONEY, BFF MONEY)
		INSERT INTO #AffTrans (AffId, AffWithdrawal, AffAdjustment, BFF)
		SELECT AffId
			  ,SUM(CASE WHEN TransType = 202 AND TransDate >= @FromDate THEN ABS(Amount) ELSE 0 END) AS AffWithdrawal
			  ,SUM(CASE WHEN TransType = 203 AND TransDate >= @FromDate THEN Amount ELSE 0 END) AS AffAdjustment
			  ,SUM(Amount) AS BFF
		FROM dbo.AffTrans WITH (NOLOCK)
		WHERE TransDate < DATEADD(DAY, 1, @ToDate)
		  AND Status IN ('Pending', 'Approved', 'Completed')
		GROUP BY AffId
	END
	
	-- Return data
	BEGIN
		CREATE TABLE #Result
		(
			AffId				INT
			,Username			NVARCHAR(30)
			,TotalClick			INT
			,UniqueClick		INT
			,Signup				INT
			,FDM				INT
			,ActiveMember		INT
			,QualifiedMember 	INT
			,Deposit			MONEY
			,Withdrawal			MONEY
			,Turnover			MONEY
			,Winlost			MONEY
			,Bonus				MONEY
			,PlatFormFee		MONEY
			,OperationalFee		MONEY
			,BankingFee			MONEY
			,CommissionRate		MONEY
			,Earning			MONEY
			,AffWithdrawal		MONEY
			,AffAdjustment		MONEY
			,BFF				MONEY
			,RowIdx				INT
			,PreferredLanguage 	VARCHAR(100)
			,FDMCommissionRate	DECIMAL(9, 8)
			,FDMEarning			MONEY
		)
		INSERT INTO #Result
		(
			AffId
			,Username
			,PreferredLanguage
			,TotalClick
			,UniqueClick
			,Signup
			,FDM
			,ActiveMember
			,QualifiedMember
			,Deposit
			,Withdrawal
			,Turnover
			,Winlost
			,Bonus
			,PlatFormFee
			,OperationalFee
			,BankingFee
			,CommissionRate
			,Earning
			,AffWithdrawal
			,AffAdjustment
			,BFF
			,FDMCommissionRate
			,FDMEarning
		)
		SELECT
			ai.AffId
			,ai.Username
			,ad.PreferredLanguage
			,ISNULL(s.TotalClick, 0)		 AS TotalClick
			,ISNULL(s.UniqueClick, 0)		 AS UniqueClick
			,ISNULL(su.Signup, 0)			 AS Signup
			,ISNULL(fdm.FDM, 0)				 AS FDM
			,ISNULL(tc.ActivePlayer, 0)		 AS ActiveMember
			,ISNULL(tc.QualifiedMember, 0)	 AS QualifiedMember
			,ISNULL(tc.Deposit, 0)			 AS Deposit
			,ISNULL(tc.Withdrawal, 0)		 AS Withdrawal
			,ISNULL(tc.Turnover, 0)			 AS Turnover
			,ISNULL(tc.Winloss, 0)			 AS Winlost
			,ISNULL(tc.Bonus, 0)			 AS Bonus
			,ISNULL(tc.PlatFormFee, 0)		 AS PlatFormFee
			,ISNULL(tc.OperationalFee, 0)	 AS OperationalFee
			,ISNULL(tc.BankingFee, 0)		 AS BankingFee
			,ISNULL(tc.CommissionRate, 0)	 AS CommissionRate
			,ISNULL(tc.Commission, 0)		 AS Earning
			,ISNULL(at.AffWithdrawal, 0)	 AS AffWithdrawal
			,ISNULL(at.AffAdjustment, 0)	 AS AffAdjustment
			,ISNULL(at.BFF, 0)				 AS BFF
			,ISNULL(tc.FDMCommissionRate, 0) AS CommissionRate
			,ISNULL(tc.FDMCommission, 0)	 AS Earning
		FROM dbo.AffInfo ai WITH (NOLOCK)
			LEFT JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffId = ad.AffId
			LEFT JOIN #Signup su ON ai.AffId = su.AffId
			LEFT JOIN #FDM fdm ON ai.AffId = fdm.AffId
			LEFT JOIN #AffTrans at ON ai.AffId = at.AffId
			LEFT JOIN (
				SELECT AffId, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
				FROM #Statistics
				GROUP BY AffId
			) s ON ai.AffId = s.AffId
			LEFT JOIN
			(
				SELECT AffId
					   ,SUM(ActivePlayer)				  AS ActivePlayer
					   ,SUM(QualifiedMember)			  AS QualifiedMember
					   ,SUM(Deposit)					  AS Deposit
					   ,SUM(Withdrawal)					  AS Withdrawal
					   ,SUM(Turnover)					  AS Turnover
					   ,SUM(Winloss)					  AS Winloss
					   ,SUM(Bonus)						  AS Bonus
					   ,SUM(PlatFormFee)				  AS PlatFormFee
					   ,SUM(OperationalFee)				  AS OperationalFee
					   ,SUM(BankingFee)					  AS BankingFee
					   ,SUM(NetWinloss)					  AS NetWinloss
					   ,SUM(CommissionRate/@NoOfMonth)	  AS CommissionRate
					   ,SUM(Commission)					  AS Commission
					   ,SUM(FDMCommissionRate/@NoOfMonth) AS FDMCommissionRate
					   ,SUM(FDMCommission)				  AS FDMCommission
				FROM #TempCommission
				GROUP BY AffId
			) tc ON ai.AffId = tc.AffId
			INNER JOIN (
				SELECT DISTINCT AffId
				FROM dbo.AffGroupHistory agh WITH (NOLOCK)
				WHERE agh.MonthDate BETWEEN @FromDate AND DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @ToDate) + 1, 0))
					AND ISNULL(agh.IsClosed, 0) = 0
			) agh ON ai.AffId = agh.AffId
		WHERE ai.Status = 'Approved'
			AND ai.Username LIKE '%' + @Username + '%'
			AND ',' + @PreferredLanguages + ',' LIKE '%,' + ad.PreferredLanguage + ',%'

		IF @Username = ''
			DELETE #Result
			WHERE
				TotalClick = 0
				AND UniqueClick = 0
				AND Signup = 0
				AND FDM = 0
				AND ActiveMember = 0
				AND QualifiedMember = 0
				AND ROUND(Deposit, 2) = 0
				AND ROUND(Withdrawal, 2) = 0
				AND ROUND(Turnover, 2) = 0
				AND ROUND(Winlost, 2) = 0
				AND ROUND(Bonus, 2) = 0
				AND ROUND(PlatFormFee, 2) = 0
				AND ROUND(OperationalFee, 2) = 0
				AND ROUND(BankingFee, 2) = 0
				AND ROUND(CommissionRate, 2) = 0
				AND ROUND(Earning, 2) = 0
				AND ROUND(AffWithdrawal, 2) = 0
				AND ROUND(AffAdjustment, 2) = 0
				AND ROUND(BFF, 2) = 0

		--Get rowId
		UPDATE x
			SET x.RowIdx = x.NewRowIdx
		FROM 
		(
			SELECT	RowIdx,
					ROW_NUMBER() OVER(ORDER BY
					CASE WHEN @SortType = 1 AND @SortDirectionType = 0 THEN Username END ASC,
					CASE WHEN @SortType = 1 AND @SortDirectionType = 1 THEN Username END DESC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 0 THEN Turnover END ASC,
					CASE WHEN @SortType = 2 AND @SortDirectionType = 1 THEN Turnover END DESC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 0 THEN Winlost	 END ASC,
					CASE WHEN @SortType = 3 AND @SortDirectionType = 1 THEN Winlost	 END DESC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 0 THEN Earning	 END ASC,
					CASE WHEN @SortType = 4 AND @SortDirectionType = 1 THEN Earning	 END DESC) AS NewRowIdx
			FROM #Result
		) x
	END
		
	SELECT @NRows = COUNT(1) FROM #Result
	IF @NRows = 0
		RETURN
		
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 0
		SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1, @RowEnd = @RowStart + @PageSize - 1
	ELSE
		SELECT @RowStart = 1, @RowEnd = @NRows

	-- Return detail
	SELECT AffId, Username, TotalClick, UniqueClick, Signup, FDM, ActiveMember, QualifiedMember, Deposit, Withdrawal, Turnover, Winlost, Bonus, PlatFormFee, OperationalFee, BankingFee, PlatFormFee + OperationalFee + BankingFee AS TotalFee, CommissionRate, Earning, AffWithdrawal, AffAdjustment, BFF, PreferredLanguage AS [Language], FDMCommissionRate, FDMEarning
	FROM #Result
	WHERE RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY RowIdx

	-- Return total
	SELECT
		SUM(TotalClick)			AS TotalClick
		,SUM(UniqueClick)		AS UniqueClick
		,SUM(Signup)			AS Signup
		,SUM(FDM)				AS FDM
		,SUM(ActiveMember)		AS ActiveMember
		,SUM(QualifiedMember)	AS QualifiedMember
		,SUM(Deposit)			AS Deposit
		,SUM(Withdrawal)		AS Withdrawal
		,SUM(Turnover)			AS Turnover
		,SUM(Winlost)			AS Winlost
		,SUM(Bonus)				AS Bonus
		,SUM(PlatFormFee)		AS PlatFormFee
		,SUM(OperationalFee)	AS OperationalFee
		,SUM(BankingFee)		AS BankingFee
		,SUM(PlatFormFee + OperationalFee + BankingFee) AS TotalFee
		,0 AS CommissionRate
		,SUM(Earning)			AS Earning
		,SUM(AffWithdrawal)		AS AffWithdrawal
		,SUM(AffAdjustment)		AS AffAdjustment
		,SUM(BFF)				AS BFF
		,0						AS FDMCommissionRate
		,SUM(FDMEarning)		AS FDMEarning
	FROM #Result

	DROP TABLE #AffTrans
	DROP TABLE #FDM
	DROP TABLE #Result
	DROP TABLE #Signup
	DROP TABLE #Statistics
	DROP TABLE #TempCommission
END
GO