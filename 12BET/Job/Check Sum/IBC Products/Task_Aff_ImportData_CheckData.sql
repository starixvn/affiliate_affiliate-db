/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData_CheckData]
	@WinlostDate	SMALLDATETIME,
	@IsCheckOnly	BIT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Check and regen data of IBC's Products

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN 
	SET NOCOUNT ON

	DECLARE @IsMatched BIT

	-- Get data from bettrans
	BEGIN
		CREATE TABLE #Data
		(
			IBCCustId		INT,
			Currency		INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Adjustment		MONEY,
			TurnOver		MONEY,
			Winloss			MONEY
		)

		INSERT INTO #Data
		(
			IBCCustId,
			Currency,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			TurnOver,
			Winloss
		)
		EXEC bodb02.dbo.Task_Aff_ImportData_Bettrans14 @WinlostDate = @WinlostDate

		CREATE NONCLUSTERED INDEX IX_IBCCustId_Currency ON #Data (IBCCustId, Currency)
	END

	-- Prepare data
	BEGIN
		CREATE TABLE #rptMemberDaily_Source
		(
			IBCCustId		INT,
			Currency		INT,
			AffId			INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Adjustment		MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			AffExRate		FLOAT,
			ExRate			FLOAT
		)
		INSERT INTO #rptMemberDaily_Source
		(
			IBCCustId,
			Currency,
			AffId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			Turnover,
			Winloss,
			AffExRate,
			ExRate
		)
		SELECT
			d.IBCCustId,
			d.Currency,
			mi.AffId,
			d.ProductId,
			d.Deposit,
			d.Withdrawal,
			d.Bonus,
			d.Adjustment,
			d.Turnover,
			d.Winloss,
			e.ActualRate2 AS AffExRate,
			e.ActualRate AS ExRate
		FROM #Data d
			CROSS APPLY dbo.Aff_f_ExchangeRateById_Sel(d.Currency, @WinlostDate) e
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.IBCCustId = mi.IBCCustID
			LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON mi.IBCCustID = mr.IBCCustID
		WHERE
			(mi.IsRemoved = 0 OR DATEDIFF(MONTH, mr.RemovedDate, @WinlostDate) < 0)
			AND DATEDIFF(DAY, mi.CreatedDate, @WinlostDate) >= 0

		CREATE TABLE #rptMemberDaily_Target
		(
			IBCCustId		INT,
			Currency		INT,
			AffId			INT,
			ProductId		INT,
			Deposit			MONEY,
			Withdrawal		MONEY,
			Bonus			MONEY,
			Adjustment		MONEY,
			Turnover		MONEY,
			Winloss			MONEY,
			AffExRate		FLOAT,
			ExRate			FLOAT
		)
		INSERT INTO #rptMemberDaily_Target
		(
			IBCCustId,
			Currency,
			AffId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			Turnover,
			Winloss,
			AffExRate,
			ExRate
		)
		SELECT
			IBCCustId,
			Currency,
			AffId,
			ProductId,
			Deposit,
			Withdrawal,
			Bonus,
			Adjustment,
			Turnover,
			Winloss,
			AffExRate,
			ExRate
		FROM dbo.rptMemberDaily WITH (NOLOCK)
		WHERE WinlostDate = @WinlostDate
	END

	-- Compare data
	BEGIN
		IF EXISTS (
			SELECT 1
			FROM #rptMemberDaily_Target t
				FULL OUTER JOIN #rptMemberDaily_Source s ON t.IBCCustId = s.IBCCustId AND t.ProductId = s.ProductId
			WHERE
				t.IBCCustId IS NULL
				OR s.IBCCustId IS NULL
				OR t.Deposit		<> s.Deposit
				OR t.Withdrawal		<> s.Withdrawal
				OR t.Bonus			<> s.Bonus
				OR t.Adjustment		<> s.Adjustment
				OR t.Turnover		<> s.Turnover
				OR t.Winloss		<> s.Winloss
				OR t.AffExRate		<> s.AffExRate
				OR t.ExRate			<> s.ExRate
		)
			SELECT @IsMatched = 0
		ELSE
			SELECT @IsMatched = 1
	END
	
	IF @IsMatched = 0
	BEGIN
		IF @IsCheckOnly = 1
		BEGIN
			PRINT 'Data on rptMemberDaily is not matched with source. '
				+ 'WinlostDate = ' + CONVERT(VARCHAR(10), @WinlostDate, 120)

			RETURN
		END

		-- Regen data into MemberDaily
		BEGIN
			MERGE dbo.rptMemberDaily AS TARGET
			USING #rptMemberDaily_Source AS SOURCE
				ON		TARGET.WinlostDate	= @WinlostDate
					AND TARGET.IBCCustId	= SOURCE.IBCCustId
					AND TARGET.ProductId	= SOURCE.ProductId
			WHEN MATCHED THEN
				UPDATE SET
					TARGET.Currency		= SOURCE.Currency,
					TARGET.AffId		= SOURCE.AffId,
					TARGET.Deposit		= SOURCE.Deposit,
					TARGET.Withdrawal	= SOURCE.Withdrawal,
					TARGET.Bonus		= SOURCE.Bonus,
					TARGET.Adjustment	= SOURCE.Adjustment,
					TARGET.Turnover		= SOURCE.Turnover,
					TARGET.Winloss		= SOURCE.Winloss,
					TARGET.AffExRate	= SOURCE.AffExRate,
					TARGET.ExRate		= SOURCE.ExRate
			WHEN NOT MATCHED BY TARGET THEN
				INSERT
				(
					WinlostDate,IBCCustId,Currency,AffId,ProductId,
					Deposit,Withdrawal,Bonus,Adjustment,
					Turnover,Winloss,AffExRate,ExRate
				)
				VALUES
				(
					@WinlostDate,SOURCE.IBCCustId,SOURCE.Currency,SOURCE.AffId,SOURCE.ProductId,
					SOURCE.Deposit,SOURCE.Withdrawal,SOURCE.Bonus,SOURCE.Adjustment,
					SOURCE.Turnover,SOURCE.Winloss,SOURCE.AffExRate,SOURCE.ExRate
				)
			WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate THEN
				DELETE;
		END
	END

	DROP TABLE #Data
	DROP TABLE #rptMemberDaily_Target
	DROP TABLE #rptMemberDaily_Source
END
GO