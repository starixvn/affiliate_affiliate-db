/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetMinReportDate]
(
	@AffId INT
)
RETURNS SMALLDATETIME
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Get min report date

	Revisions:
		- 20200220@Percy: Initialize function [RedmineID: #128775]
*/

BEGIN
	DECLARE @MinReportDate SMALLDATETIME
	SELECT  @MinReportDate = CONVERT(DATE, SValue) FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = 'SoftLaunchDate'

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