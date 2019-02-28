/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="" isFunction="0" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_ImportData]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Job - Import data of IBC's Products

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20190108@Percy: Get Product List from bettrans (IsIBC = 1) [RedmineID: #107623]
		- 20190116@Percy: Add transfer: ProductId = -1 [RedmineID: #107623]
		- 20180117@Percy: Check product by releasedDate [RedmineID: #106503]
*/

BEGIN 
	SET NOCOUNT ON

	-- Get Product List
	BEGIN
		DECLARE @Products TABLE (ProductId INT PRIMARY KEY)
		INSERT INTO @Products (ProductId)
		SELECT ProductId FROM dbo.Products WITH (NOLOCK) WHERE IsIBC = 1 AND ReleasedDate <= @WinlostDate

		INSERT INTO @Products (ProductId)
		VALUES (-1)
	END

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
		EXEC bodb02.dbo.Task_Aff_ImportData_Bettrans @WinlostDate = @WinlostDate

		CREATE NONCLUSTERED INDEX IX_IBCCustId_Currency ON #Data (IBCCustId, Currency)
	END

	-- Prepare data
	BEGIN
		CREATE TABLE #rptMemberDaily
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
		INSERT INTO #rptMemberDaily
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
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON d.IBCCustId = mi.IBCCustId
			LEFT JOIN dbo.MemberRemoval mr WITH (NOLOCK) ON mi.IBCCustId = mr.IBCCustID
		WHERE
			(mi.IsRemoved = 0 OR DATEDIFF(MONTH, mr.RemovedDate, @WinlostDate) < 0)
			AND DATEDIFF(DAY, mi.CreatedDate, @WinlostDate) >= 0
	END
	
	-- Insert data into MemberDaily
	BEGIN
		MERGE dbo.rptMemberDaily AS TARGET
		USING #rptMemberDaily AS SOURCE
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
		WHEN NOT MATCHED BY SOURCE AND TARGET.WinlostDate = @WinlostDate AND TARGET.ProductId IN (SELECT ProductId FROM @Products) THEN
			DELETE;
	END

	DROP TABLE #Data
	DROP TABLE #rptMemberDaily
END
GO