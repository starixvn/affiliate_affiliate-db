/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_DailyEarning_Detail_Sel]
	@AffId			INT
	,@ProductId		INT = 0
	,@MonthDate		SMALLDATETIME
	,@Currencies	VARCHAR(MAX) = ''
	,@BaseCurrency	INT = 0
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:
		User site - Statement History - Daily Earning - Detail
		Admin site - Customer - Statement History - Daily Earning - Detail

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
		- 20210317@Percy: Change commission formula [RedmineID: #151391]
		- 20210714@Percy: Show TO, WL = 0 for P2P Products [RedmineID: #157958]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @EndOfMonth SMALLDATETIME
	SELECT  @EndOfMonth = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @MonthDate) + 1, 0))

	-- Get Data
	BEGIN
		DECLARE @Products TABLE (ProductId INT, IsStraightSetting BIT)
		
		INSERT INTO @Products (ProductId, IsStraightSetting)
		SELECT DISTINCT dsh.ProductId, 0
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
		WHERE dsh.ProductId > 0
			AND agh.MonthDate = @EndOfMonth
			AND agh.AffID = @AffId

		INSERT INTO @Products (ProductId, IsStraightSetting)
		SELECT DISTINCT ssh.ProductId, 1
		FROM dbo.AffGroupHistory agh WITH (NOLOCK)
			INNER JOIN dbo.StraightSettingHistory ssh WITH (NOLOCK) ON agh.GroupId = ssh.GroupId AND agh.MonthDate = ssh.MonthDate
		WHERE ssh.ProductId > 0
			AND agh.MonthDate = @EndOfMonth
			AND agh.AffID = @AffId

		IF @ProductId <> 0
			DELETE @Products WHERE ProductId <> @ProductId

		SELECT mi.CustId, mi.UserName, mi.IBCUsername, r.Deposit, r.Withdrawal, r.Turnover, r.Winloss, r.Bonus, r.Rebate
		FROM (
			SELECT r.CustId
				,SUM(ISNULL(r.Deposit * e.Rate, 0))		AS Deposit
				,SUM(ISNULL(r.Withdrawal * e.Rate, 0))	AS Withdrawal
				,SUM(ISNULL(r.Bonus * e.Rate, 0))		AS Bonus
				,SUM(ISNULL(r.Rebate * e.Rate, 0))		AS Rebate
				,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 0 THEN r.Turnover ELSE 0 END * e.Rate, 0)) AS Turnover
				,SUM(ISNULL(CASE WHEN p.IsStraightSetting = 0 THEN r.Winloss ELSE 0 END * e.Rate, 0)) AS Winloss
			FROM dbo.rptMemberDaily r WITH (NOLOCK)
				LEFT JOIN @Products p ON r.ProductId = p.ProductId
				CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(r.WinlostDate, r.Currency, @BaseCurrency) e
			WHERE r.AffId = @AffId
				AND r.WinlostDate = @MonthDate
				AND (r.ProductId <= 0 OR p.ProductId IS NOT NULL)
				AND NOT EXISTS (
					SELECT 1 FROM dbo.MemberRemoval mr WITH (NOLOCK)
					WHERE mr.CustId = r.CustId
						AND mr.RemovedDate <= @EndOfMonth
				)
				AND (@Currencies = '' OR ',' + @Currencies + ',' LIKE '%,' + CONVERT(VARCHAR(5), r.Currency) + ',%')
			GROUP BY r.CustId
		) r
			INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON r.CustId = mi.CustId
	END
END
GO