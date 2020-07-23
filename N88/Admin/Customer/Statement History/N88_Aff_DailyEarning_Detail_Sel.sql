/*<info serverAlias="DBAFFN88-Affiliate_N88" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88
	Task:
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- Get Data
	BEGIN
		-- Get Banking Fee
		DECLARE @BankingRate DECIMAL(9, 8) = 0, @BankingAmount MONEY = 0
		SELECT  @BankingRate = ISNULL(dsh.DeductedPercentage, 0), @BankingAmount = ISNULL(dsh.DeductedAmount, 0)
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
		WHERE agh.AffId = @AffId AND agh.MonthDate = @EndOfMonth
			AND dsh.DeductionID = 12 -- Banking Fee

		IF @BaseCurrency <> 0
		BEGIN
			DECLARE @AffCurrency INT
			SELECT  @AffCurrency = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AffCurrency'

			SELECT @BankingAmount = @BankingAmount * Rate FROM dbo.Aff_f_ExchangeRate_Sel(@EndOfMonth, @AffCurrency, @BaseCurrency)
		END

		-- rptMemberDaily
		BEGIN
			SELECT
				mi.CustId
				,mi.UserName
				,mi.IBCUsername
				,r.Deposit
				,r.Withdrawal
				,r.Turnover
				,r.Winloss		AS Winlost
				,r.Bonus
				,(r.Deposit + r.Withdrawal) * ISNULL(@BankingRate, 0) + ISNULL(@BankingAmount, 0) AS BankingFee
			FROM
			(
				SELECT
					r.CustId
					,SUM(r.Deposit * e.Rate)	AS Deposit
					,SUM(r.Withdrawal * e.Rate)	AS Withdrawal
					,SUM(r.Turnover * e.Rate)	AS Turnover
					,SUM(r.Winloss * e.Rate)	AS Winloss
					,SUM(r.Bonus * e.Rate)		AS Bonus
				FROM dbo.rptMemberDaily r WITH (NOLOCK)
					CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, r.Currency, @BaseCurrency) e
				WHERE r.WinlostDate = @MonthDate
					AND r.AffId = @AffId
					AND (@ProductId = 0 OR r.ProductId < 0 OR r.ProductId = @ProductId)
					AND (@Currencies = '' OR ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
					AND NOT EXISTS (
						SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
						WHERE mr.CustId = r.CustId
							AND mr.RemovedDate <= @EndOfMonth
					)
				GROUP BY
					r.CustId
			) r
				INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON r.CustId = mi.CustId
		END
	END
END
GO