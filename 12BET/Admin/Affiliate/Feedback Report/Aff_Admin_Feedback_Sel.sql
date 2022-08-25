/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Feedback_Sel]
	@AffName			NVARCHAR(50) = ''
	,@RateIds			VARCHAR(100) = ''
	,@FromDate			SMALLDATETIME
	,@ToDate			SMALLDATETIME
	,@IsExportExcel		BIT	= 0
	,@PageSize			INT = 20
	,@PageIndex			INT = 1
	,@NRows				INT = 0 OUTPUT
AS

/*
	Created: 20220808@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Feedback Report - Search

	Revisions:
		- 20220808@Eddie: Initialize SP [RedmineID: #175628]

	Param's Explanation:
		- @RateIds:'0,1,2,3,4,5'
			 0 = None
			 1 = Dissatisfaction
			 2 = Unsatisfied
			 3 = Neutral
			 4 = Satisfied
			 5 = Very Pleased
		- @IsExportExcel
			 0 = Feedback cannot be extracted in Excel file.
			 1 = Feedback can be extracted in Excel file.
*/

BEGIN
	SET NOCOUNT ON
	
	SELECT @AffName = ISNULL(@AffName, ''), @RateIds = ISNULL(@RateIds, '')

	DECLARE @RowStart INT, @RowEnd INT	
	
	DECLARE @Ratetbl TABLE(RateId SMALLINT PRIMARY KEY, RateName VARCHAR(200))
	
	INSERT INTO @Ratetbl(RateId, RateName)
	EXEC dbo.Aff_RateSel
	
	SELECT @AffName = '%' + @AffName + '%'
	
	SELECT @NRows = COUNT(1)
	FROM dbo.AffFeedback af WITH (NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffID = af.AffId
		INNER JOIN @Ratetbl r ON r.RateId = af.RateId
	WHERE(ai.UserName LIKE @AffName OR @AffName = '')
		AND ( ',' + @RateIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), af.RateId) + ',%')
		AND af.SentDate >= @FromDate AND af.SentDate < DATEADD(DAY, 1, @ToDate)
		
	IF @NRows = 0
		RETURN
	
	IF @IsExportExcel = 0
	BEGIN
		SELECT  @RowStart = (@PageIndex - 1) * @PageSize + 1,
				@RowEnd = @RowStart + @PageSize - 1
	END
	ELSE -- export file excel
	BEGIN
		SELECT  @RowStart = 1,
				@RowEnd = @NRows
	END
	
	SELECT n.AffId, n.UserName, n.SentDate, n.RateName, n.Message
	FROM
	(
		SELECT 
			 ai.AffId
			,ai.UserName
			,af.SentDate
			,r.RateName
			,af.Message
			,ROW_NUMBER() OVER (ORDER BY af.SentDate DESC, UserName ASC) AS RowIdx
		FROM dbo.AffFeedback af WITH (NOLOCK)
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffID = af.AffId
			INNER JOIN @Ratetbl r ON r.RateId = af.RateId
		WHERE(ai.UserName LIKE @AffName OR @AffName = '')
			AND (',' + @RateIds + ',' LIKE '%,' + CONVERT(VARCHAR(20), af.RateId) +',%')
			AND af.SentDate >= @FromDate AND af.SentDate < DATEADD(DAY, 1, @ToDate)
	) AS n
	WHERE n.RowIdx BETWEEN @RowStart AND @RowEnd
	ORDER BY n.RowIdx ASC, UserName ASC
END
GO