/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250307@Sally
	DB: DB12B-bodb_12B
	Task: Migration Specific Affiliate [RedmineId : #212201]

*/
USE bodb_12B
GO
	DECLARE @AffIds NVARCHAR (MAX) = '1743474,2028207'

    CREATE TABLE #TempAffiliateData (
        row_num INT IDENTITY(1,1),
        CustId INT,
        SiteId INT,
        AffiliateId INT,
        AffiliateName NVARCHAR(30),
        ParentAffiliate NVARCHAR(30),
        AffiliateCode VARCHAR(20),
        UserName VARCHAR(30),
		FirstName NVARCHAR(50),
        LastName NVARCHAR(50),
        ContactNumber VARCHAR(50),
        Email NVARCHAR(50),
        Status VARCHAR(30)
    );

       INSERT INTO #TempAffiliateData(
                CustId,
                SiteId,
                AffiliateId,
                AffiliateName,
                ParentAffiliate,
                AffiliateCode,
                UserName,
				FirstName,
                LastName,
                ContactNumber,
                Email,
                Status
            )
			SELECT 
				ad.Player_CustId as CustId,
				101 AS SiteId,
				a.AffId as AffiliateId,
				a.UserName as AffiliateName,
				p.UserName AS ParentAffiliate,
				a.AffCode as AffiliateCode,
				ad.Player_Username as UserName,
				a.FirstName,
				a.LastName,
				ad.Phone as ContactNumber,
				a.Email,
				CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status 
			FROM Affiliate_12B.dbo.AffInfo a WITH(NOLOCK)
			INNER JOIN Affiliate_12B.dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
			LEFT JOIN Affiliate_12B.dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
            WHERE a.AffId IN (SELECT CONVERT(INT, [value]) FROM STRING_SPLIT(@AffIds, ','))
			    AND a.Status = 'Approved'
                AND ad.Player_CustId IS NOT NULL
			ORDER by a.AffId  DESC
    DECLARE @TotalRows INT, @CurrentRow INT = 1, @json NVARCHAR(MAX), @MessageError NVARCHAR(500);

    SELECT @TotalRows = max(row_num) FROM #TempAffiliateData;
    WHILE @CurrentRow <= @TotalRows
    BEGIN
        ;SELECT @json = (
            SELECT 
                CustId,
                SiteId,
                AffiliateId,
                AffiliateName,
                ParentAffiliate,
                AffiliateCode,
                UserName,
				FirstName,
                LastName,
                ContactNumber,
                Email,
                Status
            FROM #TempAffiliateData
            WHERE row_num = @CurrentRow
            FOR JSON PATH, WITHOUT_ARRAY_WRAPPER, INCLUDE_NULL_VALUES
        )
        INSERT INTO bodb_12B.dbo.API_PushDataTracker
            (CheckInTime, FinishedTime, StatusId, PushDataType, PushDataInfo)
        SELECT GETDATE() AS CheckInTime, NULL AS FinishedTime, 0 as StatusId, '1' PushDataType, @json AS PushDataInfo;

        SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
		RAISERROR (@MessageError, 0, 1) WITH NOWAIT

        SET @CurrentRow += 1;
        SET @json = NULL;
        
    END
DROP TABLE #TempAffiliateData;
