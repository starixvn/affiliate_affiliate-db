/*<info serverAlias="DBAFFN8B-Affiliate_N8B" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_ImportData_3rdProducts]
	@WinlostDate SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
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
			CustId			INT
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
			CustId
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
			mi.CustId
			,mi.Currency
			,mi.AffId
			,p.ProductId
			,0 AS Deposit
			,0 AS Withdrawal
			,0 AS Bonus
			,0 AS Adjustment
			,SUM(b.Stake * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)			AS Turnover
			,SUM(b.WinlostAmount * 1.0 / CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END)	AS Winloss
			,e.Rate
		FROM bodb_N88.dbo.TpBetRecord b WITH (NOLOCK)
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON b.CustId = mi.CustId
			INNER JOIN @Products p ON b.GameType = p.RefProductId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(b.winlostdate, mi.currency, 0) e
		WHERE b.WinlostDate = @WinlostDate
			AND b.TicketStatus IN (1, 2, 4) -- Won/Lose/Draw
		GROUP BY
			mi.CustId
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
			,CustId			INT
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
			SELECT AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate
			FROM dbo.rptMemberDaily WITH (NOLOCK)
			WHERE winlostdate = @WinlostDate
				AND ProductId IN (SELECT ProductId FROM @Products)
		)
		INSERT INTO #_CheckData (ModifiedType, CustId, ProductId, AffId, Currency, AffExRate, Bonus, Turnover, Winloss, Deposit, Withdrawal, Adjustment)
		SELECT
			CASE	WHEN t.CustId IS NULL THEN -1 -- delete
					WHEN r.CustId IS NULL THEN 1 -- insert
					ELSE 0 END AS ModifiedType -- update
			,ISNULL(t.CustId, r.CustId) AS CustId
			,ISNULL(t.ProductId, r.ProductId) AS ProductId
			,t.AffId, t.Currency, t.AffExRate, t.Bonus, t.Turnover, t.Winloss
			,t.Deposit, t.Withdrawal, t.Adjustment
		FROM #rptMemberDaily t
			FULL OUTER JOIN CTE_rptMemberDaily r ON t.CustId = r.CustId AND t.ProductId = r.ProductId
		
		-- Delete
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = -1)
		BEGIN
			DELETE r WITH (ROWLOCK, UPDLOCK)
			FROM dbo.rptMemberDaily r
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = -1

			DELETE #_CheckData WHERE ModifiedType = -1
		END
				
		-- Insert
		IF EXISTS (SELECT 1 FROM #_CheckData WHERE ModifiedType = 1)
		BEGIN
			DELETE #_CheckData
			OUTPUT @WinlostDate,DELETED.AffId,DELETED.CustId,DELETED.ProductId
					,DELETED.Deposit,DELETED.Withdrawal,DELETED.Bonus,DELETED.Adjustment,DELETED.Turnover,DELETED.Winloss
					,DELETED.Currency,DELETED.AffExRate
			INTO dbo.rptMemberDaily(WinlostDate,AffId,CustId,ProductId,Deposit,Withdrawal,Bonus,Adjustment,Turnover,Winloss,Currency,AffExRate)
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
				INNER JOIN #_CheckData d ON r.winlostdate = @WinlostDate AND d.CustId = r.CustId AND d.ProductId = r.ProductId
			WHERE d.ModifiedType = 0
				AND (
					r.AffId						<> d.AffId
					OR ISNULL(r.Bonus, 0)		<> ISNULL(d.Bonus, 0)
					OR ISNULL(r.Turnover, 0)	<> ISNULL(d.Turnover, 0)
					OR ISNULL(r.Winloss, 0)		<> ISNULL(d.Winloss, 0)
					OR ISNULL(r.Deposit, 0)		<> ISNULL(d.Deposit, 0)
					OR ISNULL(r.Withdrawal, 0)	<> ISNULL(d.Withdrawal, 0)
					OR ISNULL(r.Adjustment, 0)	<> ISNULL(d.Adjustment, 0)
					OR ISNULL(r.Currency, 0)	<> ISNULL(d.Currency, 0)
					OR ISNULL(r.AffExRate, 0)	<> ISNULL(d.AffExRate, 0)
				)
		END
	END

	DROP TABLE #_CheckData
	DROP TABLE #rptMemberDaily
END
GO