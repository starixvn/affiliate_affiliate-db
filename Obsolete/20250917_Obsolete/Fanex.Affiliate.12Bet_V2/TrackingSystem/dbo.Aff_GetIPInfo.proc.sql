/*<info serverAlias="DBCUST-IPDB" executers="bodbDownlineNet" viewers="vnteam" isFunction="0" isNested="0"></info>*/

ALTER PROCEDURE [dbo].[Aff_GetIPInfo]
	@IP VARCHAR(15)
AS
/*
	Created by: 20151005@Bobby
	Task: 12Bet Affiliate - Check for redirecting to EURO site
	DB: DBCUST/IPDB
	Original: Acc_GetIPInfo_Full
		
	Revision:
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @IPVal bigint


	SET @IPVal = dbo.ipConvert(@IP)

	SELECT Code, Country, Region, City 
	FROM (
		SELECT TOP 1 ipTo
			, countrySHORT as Code
			, countryLONG as Country 
			, ipRegion as Region
			, ipCity as City
		FROM IPTable with (nolock) 
		WHERE @IPVal >= IPFrom 
		ORDER BY IPFrom DESC
	) AS X
	WHERE @IPVal <= IPTo
END
GO