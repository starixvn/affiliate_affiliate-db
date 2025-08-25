/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_Report_PlayerCPA_TO_Detail]
	@MemberCPAID INT
/*
	Created: 20250822@Danny
	Task:         Player CPA Report
	DB:           DBAFF12B-Affiliate_12B
	Revisions:
		- 20250822@Danny: Initial [RedmineID: #228530]
*/
AS
BEGIN
	-- TODO: get data by groupproductId
	CREATE TABLE #data (
		MemberCPA_ID INT
		, MemberCPATier_ID INT
		, GroupProductId TINYINT
		, Turnover MONEY
		, CPAAmount MONEY
	)
	INSERT INTO #data (
		MemberCPA_ID
		, MemberCPATier_ID
		, GroupProductId
		, Turnover
		, CPAAmount
	)
	SELECT 
		MemberCPA_ID
		, MemberCPATier_ID
		, GroupProductId
		, SUM(Turnover) AS Turnover
		, SUM(CPAAmount) AS CPAAmount
	FROM MemberCPATier WITH (NOLOCK)
	WHERE MemberCPA_ID = @MemberCPAID
	GROUP BY 
        MemberCPA_ID
        , MemberCPATier_ID
        , GroupProductId;

	-- TODO: Return by GroupProductId
	SELECT 
		MemberCPA_ID AS MemberCPAId
        , MemberCPATier_ID AS MemberCPATierId
        , GroupProductId
		, Turnover
		, CPAAmount
	FROM #data
    ORDER BY GroupProductId;

    -- TODO: Return by ProductId
    SELECT 
        d.MemberCPA_ID AS MemberCPAId
        , d.MemberCPATier_ID AS MemberCPATierId
        , d.GroupProductId
        , mp.ProductId
		, p.ProductName
        , SUM(mp.Turnover) AS Turnover
    FROM #data d
    INNER JOIN MemberCPAProduct mp WITH (NOLOCK) ON d.MemberCPA_ID = mp.MemberCPA_ID AND d.MemberCPATier_ID = mp.MemberCPATier_ID
	INNER JOIN Products p WITH (NOLOCK) ON mp.ProductId = p.ProductId
    GROUP BY d.MemberCPA_ID, d.MemberCPATier_ID, d.GroupProductId, mp.ProductId, p.ProductName
    ORDER BY d.GroupProductId, mp.ProductId;

    -- TODO: Return total
    SELECT
        SUM(Turnover) AS Turnover
        , SUM(CPAAmount) AS CPAAmount
    FROM #data;

    DROP TABLE #data;
END;
