/*<info serverAlias="DBAFF12BET-Affiliate_12BET" selecters="bodbAdminNet" viewers="" isFunction="1" isNested="1"></info>*/
USE [Affiliate_12BET]
GO

ALTER FUNCTION [dbo].[Aff_f_GetSettingAll]
(
	@AffId			INT,
	@ProductId		INT,
	@WinlostDate	SMALLDATETIME
)
RETURNS TABLE
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core function - Get all Settings

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

RETURN
	SELECT
		SUM(CASE WHEN dsh.DeductionId = 10 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS FlatFormFee,
		SUM(CASE WHEN dsh.DeductionId = 11 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS OperationalFee,
		SUM(CASE WHEN dsh.DeductionId = 12 THEN ISNULL(dsh.DeductedPercentage, 0) ELSE 0 END) AS BankingFee
	FROM dbo.AffGroupHistory agh WITH (NOLOCK)
		INNER JOIN dbo.DeductionSettingHistory dsh WITH (NOLOCK) ON agh.GroupId = dsh.GroupId AND agh.MonthDate = dsh.MonthDate
		INNER JOIN dbo.CommGroupHistory cgh WITH (NOLOCK) ON agh.GroupID = cgh.GroupID AND agh.MonthDate = cgh.MonthDate
	WHERE agh.AffId = @AffId
		AND dsh.ProductId = @ProductId
		AND agh.MonthDate = DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @WinlostDate) + 1, 0))
GO