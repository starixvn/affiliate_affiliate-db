/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Campaign_ManageSel]
	@CampaignSearch	VARCHAR(100)  = ''
	,@StatusIds		VARCHAR(50)   = ''
	,@Description	VARCHAR(500)  = ''
	,@IsExportExcel BIT = 0
	,@PageIndex 	INT = 1
    ,@PageSize 		INT = 20
    ,@NRows 		INT = 0 OUTPUT
AS

/*
	Created: 20250903@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Marketing tools - Campaign Management

	Revisions:
		- 20250903@Eddie: Initialize SP [RedmineID: #236797]

	Param's Explanation:
		- @CampaignSearch:
			+ '' 	: all campaign codes AND Name
			+ 'ABC' : campaign codes include the text 'ABC' OR campaign names include the text 'ABC'
	
		- @StatusIds:
			+ '0,1,2,3' : all statuses
			+ '0,2'     : multiple statuses
			+ '1'       : single status
		- @Description:
			+ '' 	: all descriptions
			+ 'abc' : descriptions include the text 'abc'
		- @PageIndex: page number (1-based)
        - @PageSize: number of records per page
        - @NRows: total number of records (OUTPUT)
        - @IsExportExcel: 
			+ 1 : return all data for Excel export
			+ 0 : return paged data
		
*/

BEGIN
	SET NOCOUNT ON;
	
	DECLARE @Status TABLE (StatusId TINYINT);
	
	INSERT INTO @Status(StatusId)
    SELECT CAST(f2.value AS TINYINT)
    FROM STRING_SPLIT(@StatusIds, ',') f2;
	
    DROP TABLE IF EXISTS #data;

    CREATE TABLE #data
    (
        CampaignId      INT
        ,CampaignName	VARCHAR(500)
        ,CampaignCode   VARCHAR(100)
        ,Description 	VARCHAR(500)
        ,Creator    	VARCHAR(30)
        ,CreatorId     	INT
        ,CreatedDate	DATE
        ,UpdatedBy		VARCHAR(30)
        ,UpdatedById	INT
        ,UpdatedDate	DATE
        ,StatusId		TINYINT
        ,Status			VARCHAR(50)
		,RowIdx			INT
    );
	
	INSERT INTO #data(
		CampaignId
		,CampaignName
		,CampaignCode
		,Description
		,Creator
		,CreatorId
		,CreatedDate
		,UpdatedBy
		,UpdatedById
		,UpdatedDate
		,StatusId
		,Status
		,RowIdx
	)
	SELECT cp.CampaignId
		  ,cp.CampaignName
		  ,cp.CampaignCode
		  ,cp.Description
		  ,u.UserName AS Creator
		  ,cp.Creator AS CreatorId
		  ,CONVERT(DATE, cp.CreatedDate) AS CreatedDate
		  ,au.UserName AS UpdatedBy
		  ,cp.UpdatedBy AS UpdatedById
		  ,CONVERT(DATE, cp.UpdatedDate) AS UpdatedDate
		  ,cp.StatusId
		  ,f.Status
		  ,ROW_NUMBER() OVER(ORDER BY cp.CampaignId DESC) AS RowIdx
	FROM dbo.LandingPage_Campaign cp WITH (NOLOCK)
		INNER JOIN dbo.Affiliate_User u WITH (NOLOCK) ON u.CustId = cp.Creator
		INNER JOIN dbo.Affiliate_User au WITH (NOLOCK) ON au.CustId = cp.UpdatedBy
		INNER JOIN dbo.Aff_f_LandingPage_Campaign_Status() f ON f.StatusId = cp.StatusId
	WHERE EXISTS(SELECT 1 FROM @Status s WHERE s.StatusId = cp.StatusId)
	AND (
		(cp.CampaignCode LIKE '%' + @CampaignSearch + '%') 
		OR (cp.CampaignName LIKE '%' + @CampaignSearch + '%')
		OR  ISNULL(@CampaignSearch, '') = ''
	)   AND (cp.Description LIKE '%' + @Description + '%' OR ISNULL(@Description, '') = '');


	-- Get total row count
    SELECT @NRows = COUNT(*) FROM #data;
	
	
	-- Paging logic
    DECLARE @RowStart INT, @RowEnd INT;

    IF @IsExportExcel = 0
    BEGIN
        SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1,
               @RowEnd = @RowStart + @PageSize - 1;
    END
    ELSE
    BEGIN
        SELECT @RowStart = 1,
               @RowEnd = @NRows;
    END
	
	SELECT CampaignId
	       ,CampaignName
	       ,CampaignCode
	       ,Description
	       ,Creator
	       ,CreatorId
	       ,CreatedDate
		   ,UpdatedBy
		   ,UpdatedById
		   ,UpdatedDate
	       ,StatusId
	       ,Status
	       ,RowIdx
	FROM #data
    WHERE RowIdx BETWEEN @RowStart AND @RowEnd
    ORDER BY RowIdx ASC;

	DROP TABLE #data;
END
