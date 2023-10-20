/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Statistics_Sel] 
	@AffID		INT,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin site - Customer - Statistics

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102322]
		- 20190808@Percy: Add Exchange [RedmineID: #106504]
		- 20221129@Malcolm: Remove UniqueClickByMonth, TotalClickByMonth [RedmineID: #176390]
		- 20230215@Eddie: Change 'ClickStatistics1Sum' to 'ClickStatisticsSum_Country_Domain' sum table [RedmineID: #177639]
		- 20230208@Bobby: Implement Bonus & FDM Setting [RedmineId : #191139]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @SignupsByMonth				INT
			,@SignupsTotal				INT
			,@FDMByMonth				INT
			,@FDMTotal					INT
			,@ActivePlayersByMonth		INT
			,@QualifiedMembersByMonth	INT
			,@FDMDepositByMonth			MONEY
			,@DepositByMonth			MONEY
			,@DepositTotal				MONEY
			,@TurnoverByMonth			MONEY
			,@TurnoverTotal				MONEY
			,@WinlostByMonth			MONEY
			,@WinlostTotal				MONEY
			,@UniqueClickPCByMonth		INT
			,@TotalClickPCByMonth		INT
			,@UniqueClickMobileByMonth	INT
			,@TotalClickMobileByMonth	INT
			,@FDMDepositTotal			MONEY

	DECLARE @FromBeginMonth SMALLDATETIME, @ToNextMonth SMALLDATETIME
	SELECT	@FromBeginMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT	@ToNextMonth	= DATEADD(MONTH, 1, @FromBeginMonth)

	SELECT  @MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- member statistics
	BEGIN
		DECLARE @MaxCommDate SMALLDATETIME
		SELECT  @MaxCommDate = CONVERT(VARCHAR(10), SValue, 120) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CommissionDate'

		DECLARE @IsSumAll BIT, @AffIds VARCHAR(MAX)
		SELECT  @AffIds = CONVERT(VARCHAR(MAX), @AffId)

		DECLARE @tempFromDate SMALLDATETIME, @tempToDate SMALLDATETIME

		DROP TABLE IF EXISTS #TempCommission;
		CREATE TABLE #TempCommission
		(
			MonthDate				SMALLDATETIME
			,AffId					INT
			,GroupId				INT
			,ProductId				INT
			,Deposit				MONEY
			,Withdrawal				MONEY
			,Bonus					MONEY
			,Turnover				MONEY
			,Winloss				MONEY
			,AWinloss				MONEY
			,AComm					MONEY
			-- Fees
			,PlatFormFee			MONEY
			,OperationalFee			MONEY
			,BankingFee				MONEY
			,ExchangeWinlossShare	MONEY
			,ExchangeCommShare		MONEY
			-- Calculation
			,GrossWinloss			MONEY
			,NetWinloss				MONEY
			,ActivePlayer			INT
			,QualifiedMember		INT
			,QMTurnover				MONEY
			,CommissionRate			FLOAT
			,Commission				MONEY
			-----FDM & Bonus
			,IsApplyBonus			BIT
			,FDMCount				INT
			,FDMDeposit				MONEY
			,FDMCommissionRate		DECIMAL(9, 8)
			,FDMCommission			MONEY
		)

		-- Uncalculated Months
		BEGIN
			SELECT	@tempFromDate	= DATEADD(DAY, 1, @MaxCommDate),
					@tempToDate		= CONVERT(DATE, GETDATE())

			SELECT  @IsSumAll = CASE WHEN @MonthDate >= @tempFromDate THEN 0 ELSE 1 END

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
				,ExchangeWinlossShare
				,ExchangeCommShare
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
				@AffIds				= @AffIds
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= @IsSumAll
				,@GetRowTotalOnly	= 1
		END

		-- Calculated Months
		BEGIN
			SELECT	@tempFromDate	= dbo.Aff_f_GetMinReportDate(@AffId),
					@tempToDate		= @MaxCommDate

			SELECT  @IsSumAll = CASE WHEN @MonthDate <= @tempToDate THEN 0 ELSE 1 END

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
				,ExchangeWinlossShare
				,ExchangeCommShare
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
				@AffIds				= @AffIds
				,@FromMonthDate		= @tempFromDate
				,@ToMonthDate		= @tempToDate
				,@ProductIds		= '0'
				,@IsSumAll			= @IsSumAll
				,@GetRowTotalOnly	= 1
		END
	END

	SELECT
		@QualifiedMembersByMonth	= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(QualifiedMember, 0) ELSE 0 END)
		,@ActivePlayersByMonth		= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(ActivePlayer, 0) ELSE 0 END)
		,@DepositByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Deposit, 0) ELSE 0 END)
		,@TurnoverByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Turnover, 0) ELSE 0 END)
		,@WinlostByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(Winloss, 0) ELSE 0 END)
		,@DepositTotal				= SUM(ISNULL(Deposit, 0))
		,@TurnoverTotal				= SUM(ISNULL(Turnover, 0))
		,@WinlostTotal				= SUM(ISNULL(Winloss, 0))
		,@FDMDepositTotal			= SUM(ISNULL(FDMDeposit, 0))
		,@FDMDepositByMonth			= SUM(CASE WHEN MonthDate = @MonthDate THEN ISNULL(FDMDeposit, 0) ELSE 0 END)
	FROM #TempCommission
	
	DROP TABLE #TempCommission

	SELECT @SignupsTotal	= COUNT(1)
		   ,@FDMTotal		= COUNT(IBCCustID)
		   ,@SignupsByMonth = COUNT(CASE WHEN creatdate >= @FromBeginMonth AND creatdate < @ToNextMonth THEN 1 ELSE NULL END)
	FROM DBDeposit.Deposit_DB.dbo.Deposit_Customer WITH (NOLOCK)
	WHERE AffiliateId = @AffId

	SELECT @FDMByMonth = COUNT(1)
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.CreatedDate >= @FromBeginMonth AND mi.CreatedDate < @ToNextMonth
		AND mi.AffId = @AffID
		AND NOT EXISTS (
			SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
			WHERE mr.IBCCustID = mi.IBCCustID AND mr.RemovedDate >= @FromBeginMonth AND mr.RemovedDate < @ToNextMonth
		)

	DECLARE @ArchiveDate SMALLDATETIME
	
	SELECT  @ArchiveDate = MAX(Date) FROM dbo.ClickStatisticsSum_Country_Domain WITH (NOLOCK)
	
	;WITH CTE_Device AS (
		SELECT DeviceType, SUM(TotalClick) AS TotalClickByMonth, SUM(UniqueClick) AS UniqueClicks
		FROM (
			SELECT ISNULL(DeviceType, 0)  AS DeviceType
				  ,COUNT(1) 			  AS TotalClick
				  ,COUNT(DISTINCT IP) 	  AS UniqueClick
			FROM dbo.ClickStatistics1 WITH (NOLOCK)
			WHERE AffId = @AffId
				AND Date >= @FromBeginMonth AND Date < @ToNextMonth
				AND Date > @ArchiveDate
			GROUP BY Country, DomainReferrer, ISNULL(DeviceType, 0), Date

			UNION ALL
			
			SELECT ISNULL(DeviceType, 0) AS DeviceType
				  ,SUM(TotalClick) 		 AS TotalClick
				  ,SUM(UniqueClick) 	 AS UniqueClick
			FROM dbo.ClickStatisticsSum_Country_Domain WITH (NOLOCK)
			WHERE AffId = @AffId
				AND Date >= @FromBeginMonth AND Date < @ToNextMonth
				AND Date <= @ArchiveDate
			GROUP BY CountryCode, DomainReferrer, ISNULL(DeviceType, 0), Date
		) AS A
		GROUP BY DeviceType
	)
	SELECT @TotalClickPCByMonth			= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(TotalClickByMonth, 0) ELSE 0 END)
		  ,@UniqueClickPCByMonth		= SUM(CASE WHEN DeviceType = 0 THEN ISNULL(UniqueClicks, 0) ELSE 0 END)
		  ,@TotalClickMobileByMonth		= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(TotalClickByMonth, 0) ELSE 0 END)
		  ,@UniqueClickMobileByMonth	= SUM(CASE WHEN DeviceType = 1 THEN ISNULL(UniqueClicks, 0) ELSE 0 END)
	FROM CTE_Device


	-- Return data
	SELECT
		ISNULL(@SignupsByMonth, 0)				AS SignupsByMonth
		,ISNULL(@SignupsTotal, 0)				AS SignupsTotal
		,ISNULL(@FDMByMonth, 0)					AS FDMByMonth
		,ISNULL(@FDMTotal, 0)					AS FDMTotal
		,ISNULL(@ActivePlayersByMonth, 0)		AS ActivePlayersByMonth
		,ISNULL(@QualifiedMembersByMonth, 0)	AS QualifiedMembersByMonth
		,ISNULL(@DepositByMonth, 0)				AS DepositByMonth
		,ISNULL(@DepositTotal, 0)				AS DepositTotal
		,ISNULL(@TurnoverByMonth, 0)			AS TurnoverByMonth
		,ISNULL(@TurnoverTotal, 0)				AS TurnoverTotal
		,ISNULL(@WinlostByMonth, 0)				AS WinlostByMonth
		,ISNULL(@WinlostTotal, 0)				AS WinlostTotal
		,ISNULL(@UniqueClickPCByMonth, 0)		AS UniqueClickPCByMonth
		,ISNULL(@TotalClickPCByMonth, 0)		AS TotalClickPCByMonth
		,ISNULL(@TotalClickMobileByMonth, 0)	AS TotalClickMobileByMonth
		,ISNULL(@UniqueClickMobileByMonth, 0)	AS UniqueClickMobileByMonth
		,ISNULL(@FDMDepositByMonth, 0)			AS FDMDepositByMonth
END
GO