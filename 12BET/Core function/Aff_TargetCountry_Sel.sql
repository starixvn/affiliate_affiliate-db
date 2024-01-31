/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_TargetCountry_Sel]
	@UserId	INT = 0
AS
/*
	Created: 20231024@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Core SP - Get TargetCountry (Preference TargetCountry)

	Revisions:
		- 20231024@Eddie: Initialize SP [RedmineID: #181590]
		- 20240124@Eddie: Hindi and Telugu [RedmineID: #200168]
	Note: Language default for target country: English for Malaysia and English (India) for India
*/
BEGIN
	SET NOCOUNT ON

	SET @UserId = ISNULL(@UserId, 0)

	DROP TABLE IF EXISTS #TargetCountry_Order

	CREATE TABLE #TargetCountry_Order(MarketID NVARCHAR(10), MarketName NVARCHAR(50), CountryCode VARCHAR(2), CountryName NVARCHAR(100), PriorityId SMALLINT DEFAULT(3), OrderId SMALLINT DEFAULT(1))

	INSERT INTO #TargetCountry_Order(MarketID, MarketName, CountryCode, CountryName)
	SELECT MarketID, MarketName, CountryCode, CountryName
	FROM TargetCountry WITH (NOLOCK)
	
	UPDATE #TargetCountry_Order
	SET PriorityId = CASE WHEN (CountryCode = 'MY' AND MarketID = 'en-GB') OR (CountryCode = 'IN' AND MarketID = 'hi') THEN 2
						  WHEN (CountryCode = 'MY' AND MarketID = 'zh-TW') OR (CountryCode = 'IN' AND MarketID = 'te-IN') THEN 1
					 ELSE PriorityId END
					 
	UPDATE #TargetCountry_Order
	SET OrderId = CASE CountryCode WHEN 'MY' THEN 1
								   WHEN 'BD' THEN 2
								   WHEN 'IN' THEN 3
								   WHEN 'ID' THEN 4
								   WHEN 'JP' THEN 5
								   WHEN 'KH' THEN 6
								   WHEN 'KR' THEN 7
								   WHEN 'TH' THEN 8
								   WHEN 'VN' THEN 9
								   WHEN 'CN' THEN 10
				  ELSE 11 END
	
	IF @UserId <> 0
	BEGIN
		DROP TABLE IF EXISTS #Tmp_TargetCountry

		SELECT tc.MarketID, tc.MarketName, tc.CountryCode, tc.CountryName, tc.PriorityId, tc.OrderID
		INTO #Tmp_TargetCountry  
		FROM dbo.Users u WITH (NOLOCK)  
			INNER JOIN dbo.UserMarket um WITH (NOLOCK) ON um.CustId = u.CustId  
			INNER JOIN #TargetCountry_Order tc ON tc.MarketID = um.MarketId  
		WHERE u.CustId = @UserId

		;WITH CTE_TargetCountry AS(
			SELECT CountryCode, MAX(PriorityId) AS PriorityId_max
			FROM #Tmp_TargetCountry
			GROUP BY CountryCode
		)
		SELECT a.OrderId, a.CountryCode AS TargetCountryCode, a.CountryName AS TargetCountryName, a.MarketID AS DefaultLanguageCode
		FROM #TargetCountry_Order a
			INNER JOIN CTE_TargetCountry b ON b.CountryCode = a.CountryCode
		WHERE a.PriorityId = b.PriorityId_max
		ORDER BY OrderId ASC
	
		DROP TABLE #Tmp_TargetCountry

	END
	ELSE
	BEGIN
		;WITH CTE_TargetCountry AS(
			SELECT CountryCode, MAX(PriorityId) AS PriorityId_max
			FROM #TargetCountry_Order
			GROUP BY CountryCode
		)
		SELECT a.OrderId, a.CountryCode AS TargetCountryCode, a.CountryName AS TargetCountryName, a.MarketID AS DefaultLanguageCode
		FROM #TargetCountry_Order a
			INNER JOIN CTE_TargetCountry b ON b.CountryCode = a.CountryCode
		WHERE a.PriorityId = b.PriorityId_max
		ORDER BY OrderId ASC
	END

	DROP TABLE #TargetCountry_Order

END
GO