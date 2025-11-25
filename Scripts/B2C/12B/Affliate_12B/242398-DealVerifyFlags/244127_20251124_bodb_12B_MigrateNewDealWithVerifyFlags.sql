/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20251124@Sally
	DB: DB12B-bodb_12B
	Task:  Migrate  PO $35, BL Cum $8, Wager 3X, Re-dep 30% Deal [RedmineID: #244127]

*/

USE bodb_12B
GO

DECLARE @GroupId INT = 69 -- PO $35, BL Cum $8, Wager 3X, Re-dep 30% Deal

DECLARE @AffIds NVARCHAR (MAX) = (SELECT STRING_AGG(CONVERT(VARCHAR(MAX), AffId), ',') 
									FROM Affiliate_12B.dbo.AffInfo WITH (NOLOCK) 
									WHERE GroupId = @GroupId)


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
        Status VARCHAR(30),
		DealVerifyFlags INT
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
                Status,
				DealVerifyFlags
            )
			SELECT 
				CASE WHEN ISNULL(ad.Player_CustId, 0) = 0 THEN -1 ELSE ad.Player_CustId END AS CustId,
				101 AS SiteId,
				a.AffId AS AffiliateId,
				a.UserName AS AffiliateName,
				ISNULL(p.UserName, '') AS ParentAffiliate,
				a.AffCode AS AffiliateCode,
				ISNULL(ad.Player_Username, '') AS UserName,
				ISNULL(a.FirstName, '') AS FirstName,
				ISNULL(a.LastName, '') AS LastName,
				ad.Phone AS ContactNumber,
				a.Email,
				CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status,
				1 AS DealVerifyFlags
			FROM Affiliate_12B.dbo.AffInfo a WITH(NOLOCK)
			INNER JOIN Affiliate_12B.dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
			LEFT JOIN Affiliate_12B.dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
            WHERE a.AffId IN (SELECT CONVERT(INT, [value]) FROM STRING_SPLIT(@AffIds, ','))
			    AND a.Status = 'Approved'
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
                Status,
				DealVerifyFlags
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