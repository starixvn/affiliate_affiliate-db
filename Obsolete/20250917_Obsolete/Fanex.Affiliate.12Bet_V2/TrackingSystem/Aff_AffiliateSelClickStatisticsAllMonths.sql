/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_AffiliateSelClickStatisticsAllMonths]
	@AffID INT,
	@TrackingCode VARCHAR(20) = NULL -- Statistics for all TrackingCode
AS

/*
	Created by: Percy
	Date: 2017-04-03
	Task: Summary of TotalClick, Unique Click for all month 
	DB: DBAFF12BET.Affiliate_12BET
	Original:

	Revisions:

	Param's Explanation:
		@AffID: id of affiliate in the system
*/

BEGIN

	SET NOCOUNT ON

	DECLARE @CurrMonth SMALLDATETIME

	SELECT @CurrMonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, CURRENT_TIMESTAMP), 0)

	IF COALESCE(@TrackingCode, '') = ''
	BEGIN
		SELECT @CurrMonth AS Date, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM (
			SELECT s.Date, COUNT(1) AS TotalClick, COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
				INNER JOIN dbo.TrackingCode a WITH(NOLOCK) ON a.TrackingID = s.TrackingID
			WHERE s.Date >= @CurrMonth AND a.AffID = @AffID
			GROUP BY s.Date
		) AS tmp

		SELECT s.Date, s.TotalClick, s.UniqueClick
		FROM dbo.ClickStatisticsSum s WITH(NOLOCK)
		WHERE s.AffID = @AffID AND s.TrackingID = 0 AND s.IsForMonth = 1
		ORDER BY s.Date DESC
 
	END
	ELSE
	BEGIN
		SELECT @CurrMonth AS Date, SUM(TotalClick) AS TotalClick, SUM(UniqueClick) AS UniqueClick
		FROM (
			SELECT s.Date, COUNT(1) AS TotalClick, COUNT(DISTINCT s.IP) AS UniqueClick
			FROM dbo.ClickStatistics s WITH(NOLOCK)
				INNER JOIN dbo.TrackingCode a WITH(NOLOCK) ON a.TrackingID = s.TrackingID
			WHERE s.Date >= @CurrMonth AND a.AffID = @AffID AND a.TrackingCode = @TrackingCode
			GROUP BY s.Date
		) AS tmp

		SELECT s.Date, s.TotalClick, s.UniqueClick
		FROM dbo.ClickStatisticsSum s WITH(NOLOCK)
		WHERE s.AffID = @AffID AND s.IsForMonth = 1
			AND EXISTS (
				SELECT 1
				FROM dbo.TrackingCode t WITH(NOLOCK)
				WHERE t.AffID = @AffID AND t.TrackingCode = @TrackingCode AND s.TrackingID = t.TrackingID
			)
		ORDER BY s.Date DESC
	END
END
GO