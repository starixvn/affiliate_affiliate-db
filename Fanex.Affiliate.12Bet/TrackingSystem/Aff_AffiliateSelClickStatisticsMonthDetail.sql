/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_AffiliateSelClickStatisticsMonthDetail]
	@AffID INT,
	@month INT, 
	@year INT,
	@TrackingCode VARCHAR(20) = NULL -- Statistics for all TrackingCode
AS

/*
	Created by: Percy
	Date: 2017-04-03
	Task: Detail of TotalClick, Unique Click for all month 
	DB: DBAFF12BET.Affiliate_12BET
	Original:

	Revisions:

	Param's Explanation:
		@AffID: id of affiliate in the system
*/
BEGIN

	SET NOCOUNT ON

	DECLARE @firstDayOfThisMonth SMALLDATETIME
	SELECT  @firstDayOfThisMonth = CAST(@year AS VARCHAR(6)) + '-' + CAST(@month AS VARCHAR(2)) + '-01'

	IF DATEDIFF(MONTH, @firstDayOfThisMonth, CURRENT_TIMESTAMP) = 0
	BEGIN
		SELECT s.Date, COUNT(1) AS TotalClick, COUNT(DISTINCT s.IP) AS UniqueClick
		FROM dbo.ClickStatistics s WITH(NOLOCK)
			INNER JOIN dbo.TrackingCode a WITH(NOLOCK) ON a.TrackingID = s.TrackingID
		WHERE s.Date >= @firstDayOfThisMonth AND a.AffID = @AffID
			AND a.TrackingCode = COALESCE(@TrackingCode, a.TrackingCode)
		GROUP BY s.Date
		ORDER BY s.Date DESC
	END
	ELSE
	BEGIN
		IF COALESCE(@TrackingCode, '') = ''
		BEGIN
			SELECT s.Date, s.TotalClick, s.UniqueClick
			FROM dbo.ClickStatisticsSum s WITH(NOLOCK)
			WHERE s.AffID = @AffID AND s.TrackingID = 0 AND s.IsForMonth = 0
				AND DATEDIFF(MONTH, @firstDayOfThisMonth, s.Date) = 0
			ORDER BY s.Date DESC
		END
		ELSE
		BEGIN
			SELECT s.Date, s.TotalClick, s.UniqueClick
			FROM dbo.ClickStatisticsSum s WITH(NOLOCK)
			WHERE s.AffID = @AffID AND s.TrackingID = 0 AND s.IsForMonth = 0
				AND DATEDIFF(MONTH, @firstDayOfThisMonth, s.Date) = 0
				AND EXISTS (
					SELECT 1
					FROM dbo.TrackingCode t WITH(NOLOCK)
					WHERE t.AffID = @AffID AND t.TrackingCode = @TrackingCode AND s.TrackingID = t.TrackingID
				)
			ORDER BY s.Date DESC
		END
	END
END
GO