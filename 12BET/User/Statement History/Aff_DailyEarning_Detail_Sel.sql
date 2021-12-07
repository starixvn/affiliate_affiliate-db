/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId		INT,
	@ProductId	INT = 0,
	@MonthDate	SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task:
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20191210@Percy: Remove get data on bettrans [RedmineID: #121971]
		- 20211207@Percy: Apply core function Group Product [RedmineID: #165777]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- Get Data
	BEGIN
		DECLARE @Products TABLE (ProductId INT)
	
		IF @ProductId > 0
			INSERT INTO @Products (ProductId)
			SELECT ISNULL(g.ProductId, p.ProductId)
			FROM dbo.Products p WITH (NOLOCK)
				LEFT JOIN dbo.Aff_f_GroupProduct() g ON p.ProductId = g.GroupProductId
			WHERE p.ProductId = @ProductId

		-- Get Banking Fee
		DECLARE @BankingFee DECIMAL(9,8)
		SELECT  @BankingFee = dsh.DeductedPercentage
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
		WHERE agh.AffId = @AffId AND agh.MonthDate = @EndOfMonth
			AND dsh.DeductionID = 12 -- Banking Fee

		DECLARE @CutOffDate SMALLDATETIME
		SELECT  @CutOffDate = CONVERT(SMALLDATETIME, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_CutOffReportDate'

		-- MemberDaily
		IF @MonthDate <= @CutOffDate
		BEGIN
			SELECT
				mi.IBCCustId	AS CustId
				,mi.UserName
				,mi.IBCUsername
				,r.Deposit
				,r.Withdrawal
				,r.Turnover
				,r.Winloss		AS Winlost
				,r.Bonus
				,(r.Deposit + r.Withdrawal) * ISNULL(@BankingFee, 0) AS BankingFee
			FROM
			(
				SELECT
					r.IBCCustId
					,SUM(r.Deposit * r.AffExRate)		AS Deposit
					,SUM(r.Withdrawal * r.AffExRate)	AS Withdrawal
					,SUM(CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Turnover * r.AffExRate ELSE 0 END) AS Turnover
					,SUM(CASE WHEN ISNULL(@ProductId, 0) = 0 OR r.SportType = @ProductId THEN r.Winlost * r.AffExRate ELSE 0 END) AS Winloss
					,SUM(r.Bonus * r.AffExRate)			AS Bonus
				FROM dbo.MemberDaily r WITH (NOLOCK)
				WHERE r.WinlostDate = @MonthDate
					AND r.AffId = @AffId
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustId = r.IBCCustId
							AND mr.RemovedDate <= @EndOfMonth
					)
				GROUP BY
					r.IBCCustId
			) r
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON r.IBCCustId = mi.IBCCustId
		END
		-- rptMemberDaily
		ELSE
		BEGIN
			SELECT
				mi.IBCCustId	AS CustId
				,mi.UserName
				,mi.IBCUsername
				,r.Deposit
				,r.Withdrawal
				,r.Turnover
				,r.Winloss		AS Winlost
				,r.Bonus
				,(r.Deposit + r.Withdrawal) * ISNULL(@BankingFee, 0) AS BankingFee
			FROM
			(
				SELECT
					r.IBCCustId
					,SUM(r.Deposit * r.AffExRate)		AS Deposit
					,SUM(r.Withdrawal * r.AffExRate)	AS Withdrawal
					,SUM(r.Turnover * r.AffExRate)		AS Turnover
					,SUM(r.Winloss * r.AffExRate)		AS Winloss
					,SUM(r.Bonus * r.AffExRate)			AS Bonus
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					LEFT JOIN @Products p ON r.ProductId = p.ProductId
				WHERE r.WinlostDate = @MonthDate
					AND r.AffId = @AffId
					AND (@ProductId = 0 OR r.ProductId < 0 OR p.ProductId IS NOT NULL)
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.IBCCustId = r.IBCCustId
							AND mr.RemovedDate <= @EndOfMonth
					)
				GROUP BY
					r.IBCCustId
			) r
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON r.IBCCustId = mi.IBCCustId
		END
	END
END
GO