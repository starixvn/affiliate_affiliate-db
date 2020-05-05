/*<info serverAlias="DBAFFN8G-Affiliate_N8G" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_3rdProducts]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Job - Import data of 3rd Products

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN 
	SET NOCOUNT ON

	-- Get data
	BEGIN
		DECLARE @Products TABLE (ProductId INT, RefProductId INT)
		INSERT INTO @Products (ProductId, RefProductId)
		SELECT ProductId, RefProductId
		FROM dbo.Products p WITH (NOLOCK)
		WHERE IsIBC = 0
			AND DataSource = 'TpBetRecord'

		CREATE TABLE #rptMemberDaily
		(
			IBCCustId		INT
			,Currency		INT
			,AffId			INT
			,ProductId		INT
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Bonus			MONEY
			,Adjustment		MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,AffExRate		FLOAT
		)
		INSERT INTO #rptMemberDaily
		(
			IBCCustId
			,Currency
			,AffId
			,ProductId
			,Deposit
			,Withdrawal
			,Bonus
			,Adjustment
			,Turnover
			,Winloss
			,AffExRate
		)
		SELECT
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,p.ProductId
			,0 AS Deposit
			,0 AS Withdrawal
			,0 AS Bonus
			,0 AS Adjustment
			,SUM(b.Stake)			AS Turnover
			,SUM(b.WinlostAmount)	AS Winloss
			,e.Rate
		FROM bodb_3rdProduct.dbo.TpBetRecord b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.IBCCustId = mi.IBCCustId
			INNER JOIN @Products p ON b.GameType = p.RefProductId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.winlostdate, mi.currency, 0) e
		WHERE mi.IBCCustId IS NOT NULL
			AND b.WinlostDate = @WinlostDate
			AND b.TicketStatus IN (1, 2, 4) -- Won/Lose/Draw
		GROUP BY
			mi.IBCCustId
			,mi.Currency
			,mi.AffId
			,p.ProductId
			,e.Rate
	END

	-- Gen data into rptMemberDaily
	BEGIN
		CREATE TABLE #_CheckData
		(
			ModifiedType	INT
			,IBCCustId		INT
			,ProductId		INT
			,AffId			INT
			,Currency		INT
			,AffExRate		FLOAT
			,Bonus			MONEY
			,Turnover		MONEY
			,Winloss		MONEY
			,Deposit		MONEY
			,Withdrawal		MONEY
			,Adjustment		MONEY
		)
		;WITH CTE_rptMemberDaily AS
		(
			SELECT AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate
				AND ProductId IN (SELECT ProductId FROM @Products)
		)
		INSERT INTO #_CheckData (ModifiedType, IBCCustId, ProductId, AffId, Currency, AffExRate, Bonus, Turnover, Winloss, Deposit, Withdrawal, Adjustment)
		SELECT
			CASE	WHEN t.IBCCustId IS NULL THEN -1 -- delete
					WHEN r.IBCCustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType -- update
			,ISNULL(t.IBCCustId, r.IBCCustId) AS IBCCustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.Bonus, t.Turnover, t.Winloss
			,t.Deposit, t.Withdrawal, t.Adjustment
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.IBCCustId = r.IBCCustId AND t.ProductId = r.ProductId
		
		-- Delete
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #_CheckData WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 1)
		BEGIN
			DELETE #_CheckData
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.IBCCustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.AffExRate
			INTO dbo.rptMemberDaily(WinlostDate,AffId,IBCCustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate)
			WHERE ModifiedType = 1
		END

		-- Update
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 0)
		BEGIN
			UPDATE r WITH (ROWLOCK)
			SET r.AffId = d.AffId
				,r.Deposit = d.Deposit
				,r.Withdrawal = d.Withdrawal
				,r.Bonus = d.Bonus
				,r.Adjustment = d.Adjustment
				,r.Turnover = d.Turnover
				,r.Winloss = d.Winloss
				,r.Currency = d.Currency
				,r.AffExRate = d.AffExRate
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.IBCCustId = r.IBCCustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId			<> d.AffId
					OR r.Bonus		<> d.Bonus
					OR r.Turnover	<> d.Turnover
					OR r.Winloss	<> d.Winloss
					OR r.Deposit	<> d.Deposit
					OR r.Withdrawal	<> d.Withdrawal
					OR r.Adjustment	<> d.Adjustment
					OR r.Currency	<> d.Currency
					OR r.AffExRate	<> d.AffExRate
				)
		END
	END

	DROP TABLE #_CheckData
	DROP TABLE #rptMemberDaily
END
GO