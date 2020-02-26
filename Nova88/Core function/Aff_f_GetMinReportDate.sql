/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetMinReportDate]
(
	@AffId INT
)
RETURNS SMALLDATETIME
AS

/*
	Created: 20180601@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Get min report date

	Revisions:
		- 20180601@Percy: Initialize function [RedmineID: #87923]
*/

BEGIN
	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = DATEADD(DAY, 1, CONVERT(DATE, SValue)) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'AFF_OldReportDate'

	IF @AffId <> 0
	BEGIN
		DECLARE @AffApprovedDate SMALLDATETIME
		SELECT  @AffApprovedDate = CONVERT(DATE, ApprovedDate) FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

		IF ISNULL(@AffApprovedDate, @MinReportDate) > @MinReportDate
			SELECT @MinReportDate = @AffApprovedDate
	END

	RETURN @MinReportDate
END
GO