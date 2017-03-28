USE [IPDB]
GO
/****** Object:  StoredProcedure [dbo].[Acc_GetIPInfo_Full]    Script Date: 10/5/2015 2:27:14 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Acc_GetIPInfo_Full    Script Date: 4/1/2010 4:40:30 PM ******/
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
GRANT EXECUTE ON [dbo].[Aff_GetIPInfo] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_GetIPInfo] TO [vnteam] AS [dbo]
GO