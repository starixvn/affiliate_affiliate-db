/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
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
		-- rptMemberDaily
		BEGIN
			SELECT
				mi.CustId
				,mi.UserName
				,mi.IBCUsername
				,r.Deposit
				,r.Withdrawal
				,r.Turnover
				,r.Winloss AS Winlost
				,r.Bonus
				,r.Rebate
			FROM
			(
				SELECT
					r.CustId
					,SUM(r.Deposit * e.Rate)			AS Deposit
					,SUM(r.Withdrawal * e.Rate)			AS Withdrawal
					,SUM(r.Turnover * e.Rate)			AS Turnover
					,SUM(r.Winloss * e.Rate)			AS Winloss
					,SUM(r.Bonus * e.Rate)				AS Bonus
					,SUM(ISNULL(r.Rebate, 0) * e.Rate)	AS Rebate
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