/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Country_Sel]
AS

/*
	Created: 20220929@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: Affiliate 12BET - Core function - Get Country

	Revisions:
		- 20220929@Eddie: Initialize SP [RedmineID: #176390]
*/

BEGIN
	SET NOCOUNT ON
	; WITH CTE_Country AS(
		SELECT CountryCode, 
			CASE WHEN CountryCode = '-' THEN 'Unknown' ELSE CountryName END AS CountryName,
			CASE WHEN CountryCode = '-' THEN 1 ELSE 2 END AS TypeID
		FROM dbo.Country WITH (NOLOCK)
	)
	SELECT CountryCode, CountryName
	FROM CTE_Country 
	ORDER BY TypeID, CountryName ASC
END
GO