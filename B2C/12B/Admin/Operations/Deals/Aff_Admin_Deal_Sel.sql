/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE dbo.Aff_Admin_Deal_Sel
    @GroupId INT = 0,
    @GroupName NVARCHAR(100) = '',
    @GroupTypeId INT = 0,
    @PageIndex INT = 1,
    @PageSize INT = 20,
    @NRows INT = 0 OUTPUT
AS

/*
	Created: 20250526@Lewis
	DB: DBAFF12B-Affiliate_12B
	Task: Admin site - Add new Deal

	Revisions:
		- 20250526@Lewis: Initialize SP [RedmineID: #228530]
*/

BEGIN
    SET NOCOUNT ON;

    -- Temporary table for paging
    CREATE TABLE #Deals (
        RowNum INT,
        GroupId INT,
        DealName NVARCHAR(100),
        DealType NVARCHAR(100),
        NoAff INT,
        Description NVARCHAR(255),
        UpdatedBy VARCHAR(30),
        UpdatedDate DATETIME
    );

    -- Insert filtered deals from CommGroup with INNER JOIN to GroupType and OUTER APPLY for NoAff
    INSERT INTO #Deals (RowNum, GroupId, DealName, DealType, NoAff, Description, UpdatedBy, UpdatedDate)
    SELECT 
        ROW_NUMBER() OVER(ORDER BY cg.UpdatedTime DESC),
		cg.GroupId,
        cg.GroupName AS DealName,
        gt.GroupTypeName AS DealType,
        ISNULL(aff.NoAff, 0) AS NoAff,
        cg.Description,
        au.Username AS UpdatedBy,
        cg.UpdatedTime
    FROM CommGroup cg WITH (NOLOCK)
    INNER JOIN GroupType gt WITH (NOLOCK) ON cg.GroupTypeId = gt.GroupTypeId
    OUTER APPLY (
        SELECT COUNT(1) AS NoAff FROM AffInfo ai WITH (NOLOCK) WHERE ai.GroupId = cg.GroupId
    ) aff
	LEFT JOIN Affiliate_User au WITH (NOLOCK) ON cg.UpdatedBy = au.CustId
    WHERE ( ISNULL(@GroupId,0) = 0 OR cg.GroupId = @GroupId )
      AND ( ISNULL(@GroupName,'') = '' OR cg.GroupName LIKE '%' + @GroupName + '%' )
      AND ( ISNULL(@GroupTypeId,0) = 0 OR cg.GroupTypeId = @GroupTypeId )
	  AND cg.IsDeleted = 0
    -- Get total rows
    SELECT @NRows = COUNT(1) FROM #Deals;

    -- Calculate row boundaries for paging
    DECLARE @RowStart INT, @RowEnd INT;
    SET @RowStart = ((@PageIndex - 1) * @PageSize) + 1;
    SET @RowEnd = @PageIndex * @PageSize;

    -- Return paged result using row boundaries
    SELECT 
        RowNum,
		GroupId,
        DealName,
        DealType,
        NoAff,
        Description,
        UpdatedBy,
        UpdatedDate
    FROM #Deals
    WHERE RowNum BETWEEN @RowStart AND @RowEnd
    ORDER BY RowNum;

    DROP TABLE #Deals;
END
GO
