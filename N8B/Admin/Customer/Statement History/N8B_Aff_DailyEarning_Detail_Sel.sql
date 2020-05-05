/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task:
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
		- 20191210@Percy: Remove get data on bettrans [RedmineID: #121971]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- Get Data
	BEGIN
		-- Get Banking Fee
		DECLARE @BankingFee DECIMAL(9,8)
		SELECT  @BankingFee = dsh.DeductedPercentage
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.MonthDate = dsh.MonthDate AND agh.GroupId = dsh.GroupId
		WHERE agh.AffId = @AffId AND agh.MonthDate = @EndOfMonth
			AND dsh.DeductionID = 12 -- Banking Fee

		-- rptMemberDaily
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