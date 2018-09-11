/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO
  
ALTER PROCEDURE [dbo].[Task_Aff_Monthly_Commission]  
	@MonthDate		SMALLDATETIME,
	@IsForceUpdate	BIT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Calculate commission monthly

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @FirstDayOfMonth SMALLDATETIME, @LastDayOfMonth SMALLDATETIME

	SELECT  @FirstDayOfMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate), 0)
	SELECT  @LastDayOfMonth  = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FirstDayOfMonth))

	-- Check month of @MonthDate is completed
	IF @LastDayOfMonth > CURRENT_TIMESTAMP
	BEGIN
		SELECT 'This month is not completed yet!'

		RETURN
	END

	-- Check settings are archived
	IF NOT EXISTS (SELECT 1 FROM dbo.CommGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.TierSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.DeductionSettingHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		OR NOT EXISTS (SELECT 1 FROM dbo.AffGroupHistory WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
	BEGIN
		SELECT 'Settings of this month are not archived yet!'

		RETURN
	END

	-- Check job run already
	IF @IsForceUpdate = 0
	BEGIN
		IF EXISTS (SELECT 1 FROM dbo.rptAffCommission WITH (NOLOCK) WHERE MonthDate = @LastDayOfMonth)
		BEGIN
			SELECT 'Data is already done for this month!'

			RETURN
		END
	END

	-- Process data
		-- Get Data
	BEGIN
		CREATE TABLE #TempCommission
		(
			MonthDate		SMALLDATETIME,
			AffId			INT,
			GroupId			INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			-- Fees
			PlatFormFee		MONEY,
			OperationalFee	MONEY,
			BankingFee		MONEY,
			-- Calculation
			NetWinloss		MONEY,
			ActivePlayer	INT,
			QualifiedMember INT,
			QMTurnover		MONEY,
			CommissionRate	DECIMAL(9,8),
			Commission		MONEY
		)

		-- Uncalculated Months
		INSERT INTO #TempCommission
		(
			MonthDate,
			AffId,
			GroupId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Turnover,
			Winloss,
			PlatFormFee,
			OperationalFee,
			BankingFee,
			NetWinloss,
			ActivePlayer,
			QualifiedMember,
			QMTurnOver,
			CommissionRate,
			Commission
		)
		EXEC dbo.Aff_Commission_UnCalc @AffIds = 'all', @FromMonthDate = @MonthDate, @ToMonthDate = @MonthDate
	END

		-- Remove invalid data
	DELETE tc
	FROM #TempCommission tc
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON tc.AffId = ai.AffId
	WHERE ai.Status <> 'Approved'

		-- Import data
	IF @IsForceUpdate = 1
	BEGIN
		DELETE dbo.rptAffCommission WITH (ROWLOCK, UPDLOCK)
		WHERE MonthDate = @LastDayOfMonth
	END

	INSERT INTO dbo.rptAffCommission
	(
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		Adjustment,
		Turnover,
		Winloss,
		NetWinloss,
		QMTurnover,
		ActivePlayer,
		QualifiedMember,
		CommissionRate
	)
	SELECT
		MonthDate,
		AffId,
		GroupId,
		ProductId,
		Deposit,
		Withdrawal,
		Bonus,
		0 AS Adjustment,
		Turnover,
		Winloss,
		NetWinloss,
		QMTurnover,
		ActivePlayer,
		QualifiedMember,
		CommissionRate
	FROM #TempCommission

	/*
	MERGE dbo.AffTrans AS TARGET
	USING
	(
		SELECT
			AffID,
			MonthDate AS TransDate,
			GETDATE() AS CompletedDate,
			NetWinloss * CommissionRate AS Amount,
			'Approved' AS Status,
			'Monthly Earning' AS Description,
			148 AS Creator,
			201 AS TransType
		FROM #TempCommission
		WHERE ProductId = 0
	) AS SOURCE
		ON		TARGET.TransDate	= SOURCE.TransDate
			AND TARGET.AffId		= SOURCE.AffId
			AND TARGET.TransType	= SOURCE.TransType
	WHEN MATCHED THEN UPDATE
		SET TARGET.Amount			= SOURCE.Amount,
			TARGET.CompletedDate	= SOURCE.CompletedDate,
			TARGET.Status			= SOURCE.Status,
			TARGET.Description		= SOURCE.Description,
			TARGET.Creator			= SOURCE.Creator
	WHEN NOT MATCHED BY TARGET THEN INSERT
		(
			AffID,TransDate,CompletedDate,Amount,
			Status,Description,Creator,TransType
		)
		VALUES
		(
			SOURCE.AffID,SOURCE.TransDate,SOURCE.CompletedDate,SOURCE.Amount,
			SOURCE.Status,SOURCE.Description,SOURCE.Creator,SOURCE.TransType
		)
	WHEN NOT MATCHED BY SOURCE AND TARGET.TransDate	= @LastDayOfMonth AND TARGET.TransType = 201 THEN DELETE;
	*/
	
	IF @IsForceUpdate = 0
		UPDATE dbo.SystemSettings WITH (ROWLOCK, UPDLOCK)
		SET SValue = CONVERT(VARCHAR(10), @LastDayOfMonth, 120)
		WHERE SName = 'AFF_CommissionDate'
END
GO