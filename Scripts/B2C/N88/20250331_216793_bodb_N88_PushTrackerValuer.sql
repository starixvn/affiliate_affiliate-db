/*<info serverAlias="DBN88-bodb_N88"></info>*/
/*
	Created: 20250331@Sally
	DB: DBN88-bodb_N88
	Task: Sync AffiliateInfo to B2C DB [RedmineID: #216793]
*/

USE bodb_N88
GO
	DECLARE @Player_CustIds VARCHAR(MAX)  ='667588,692868,624322,700887,11802,67836,90538,349797,85573,379785,121300,424639,705666,1111349,14737,1547589,566679,855107,853892,806582,548792,507647,502532,487664,427200,383907,427243,387584,183818,94802,2088,93515,82999,83048,1090933,158877,439449,928563,611654,617972'
	DECLARE @Player_CustId TABLE (Player_CustId INT)

	INSERT INTO @Player_CustId(Player_CustId)
	SELECT CONVERT(INT, value) as Player_CustId
	FROM STRING_SPLIT(@Player_CustIds, ',') t

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

	-- ~ 40 rows
	INSERT INTO #TempAffiliateData ([CustId], [SiteId], [AffiliateName], [ParentAffiliate], [AffiliateCode], [UserName], [FirstName], [LastName], [ContactNumber], [Status], [Email], [AffiliateId])
		SELECT 	
			ad.Player_CustId	AS CustId
			,1					As SiteId
			,a.UserName			AS  AffiliateName
			,ISNULL(p.UserName,'')	AS  ParentAffiliate
			,a.AffCode			AS  AffiliateCode  
			,ad.Player_Username AS UserName
			,a.FirstName 
			,a.LastName 
			,ad.Phone			AS ContactNumber 
			,CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status  
			,a.Email  
			,a.AffId			AS AffiliateId  
		FROM Affiliate_N88.dbo.AffInfo a WITH(NOLOCK)
			INNER JOIN Affiliate_N88.dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
			INNER JOIN @Player_CustId pc on pc.Player_CustId = ad.Player_CustId
			LEFT JOIN Affiliate_N88.dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
		WHERE a.Status = 'Approved' 

		UNION ALL

		SELECT 	
			ad.Player_CustId	AS CustId
			,2					As SiteId
			,a.UserName			AS  AffiliateName
			,ISNULL(p.UserName,'')	AS  ParentAffiliate
			,a.AffCode			AS  AffiliateCode  
			,ad.Player_Username AS UserName
			,a.FirstName 
			,a.LastName 
			,ad.Phone AS ContactNumber 
			,CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status  
			,a.Email  
			,a.AffId AS AffiliateId  
		FROM Affiliate_N8G.dbo.AffInfo a WITH(NOLOCK)
			INNER JOIN Affiliate_N8G.dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
			INNER JOIN @Player_CustId pc on pc.Player_CustId = ad.Player_CustId
			LEFT JOIN Affiliate_N8G.dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
		WHERE a.Status = 'Approved' 

		UNION ALL

		SELECT 	
			ad.Player_CustId	AS CustId
			,3					As SiteId
			,a.UserName			AS  AffiliateName
			,ISNULL(p.UserName,'')	AS  ParentAffiliate
			,a.AffCode			AS  AffiliateCode  
			,ad.Player_Username AS UserName
			,a.FirstName 
			,a.LastName 
			,ad.Phone AS ContactNumber 
			,CASE WHEN a.IsRejected = 0 THEN a.Status ELSE 'Suspended' END AS Status  
			,a.Email  
			,a.AffId AS AffiliateId  
		FROM Affiliate_N8B.dbo.AffInfo a WITH(NOLOCK)
			INNER JOIN Affiliate_N8B.dbo.AffDetail ad WITH(NOLOCK) ON ad.AffId = a.AffId
			INNER JOIN @Player_CustId pc on pc.Player_CustId = ad.Player_CustId
			LEFT JOIN Affiliate_N8B.dbo.AffInfo p WITH(NOLOCK) ON p.AffId = a.ParentAffId
		WHERE a.Status = 'Approved' 

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
        INSERT INTO bodb_N88.dbo.API_PushDataTracker
            (CheckInTime, FinishedTime, StatusId, PushDataType, PushDataInfo)
        SELECT GETDATE() AS CheckInTime, NULL AS FinishedTime, 0 as StatusId, '1' PushDataType, @json AS PushDataInfo;

        SET @MessageError = CONVERT(VARCHAR(50), GETDATE(), 121)			
		RAISERROR (@MessageError, 0, 1) WITH NOWAIT

        SET @CurrentRow += 1;
        SET @json = NULL;
        
    END
DROP TABLE #TempAffiliateData;
