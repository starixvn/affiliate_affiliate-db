/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_GetMinReportDate]
(
	@AffId INT
)
RETURNS SMALLDATETIME
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Get min report date

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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