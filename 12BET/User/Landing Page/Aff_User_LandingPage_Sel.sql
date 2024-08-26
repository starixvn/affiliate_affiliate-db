/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_LandingPage_Sel]
	@TargetCountryCode	VARCHAR(2) = NULL
AS

/*
	Created: 20231123@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task: User Site - Link to - select

	Revisions:
		- 20231123@Eddie: Initialize SP [RedmineID: #181590]
		- 20240821@Eddie: Change metadata "bodbDownlineNet,bodbDownlineNetView" [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON
	
	;WITH CTE_LandingPage AS (  
		SELECT 
			lp.PageId
			,lp.PageName
			,lp.PageCode
			,CASE WHEN lp.PageName = 'ODI World Cup'  AND lp.PageCode = 'iccwc2023' 			 THEN 1
				  WHEN lp.PageName = 'MKT Sign Up'    AND lp.PageCode = 'inrsignup' 			 THEN 2
				  WHEN lp.PageName = 'Sign Up' 	  	  AND lp.PageCode = 'signup'    			 THEN 3
				  WHEN lp.PageName = 'Home' 		  AND lp.PageCode = 'home'      		     THEN 4
				  WHEN lp.PageName = 'Cricket' 	  	  AND lp.PageCode = '12sports/cricket' 	     THEN 5
				  WHEN lp.PageName = 'Exchange' 	  AND lp.PageCode = 'exchange'			     THEN 6
				  WHEN lp.PageName = 'Sportsbook' 	  AND lp.PageCode = 'sportsbook'			 THEN 7
				  WHEN lp.PageName = 'Promotion' 	  AND lp.PageCode = 'promotion'			     THEN 8
				  WHEN lp.PageName = 'Live Casino'    AND lp.PageCode = 'livecasino'			 THEN 9
				  WHEN lp.PageName = 'Casino'   	  AND lp.PageCode = 'casino'				 THEN 10
				  WHEN lp.PageName = 'Playtech'   	  AND lp.PageCode = 'playtech'			     THEN 11
				  WHEN lp.PageName = 'Number Game'    AND lp.PageCode = 'numbergame'			 THEN 12
				  WHEN lp.PageName = 'Keno'   		  AND lp.PageCode = 'keno'				     THEN 13
				  WHEN lp.PageName = 'Lottery'   	  AND lp.PageCode = 'lottery'				 THEN 14
				  WHEN lp.PageName = 'E-sports'   	  AND lp.PageCode = 'esports'				 THEN 15
				  WHEN lp.PageName = 'Arcade'   	  AND lp.PageCode = 'arcade'				 THEN 16
				  WHEN lp.PageName = 'P2P'   	      AND lp.PageCode = 'p2p'					 THEN 17
				  WHEN lp.PageName = '12Bet Casino'   AND lp.PageCode = 'livecasino'			 THEN 18
				  WHEN lp.PageName = 'Virtual Sports' AND lp.PageCode = '12sports/virtualsports' THEN 19
			 ELSE 20 END AS OrderID  
		FROM dbo.LandingPage lp WITH (NOLOCK)
			OUTER APPLY(
				SELECT t.CountryCode
				FROM(
					SELECT DISTINCT CountryCode
					FROM dbo.TargetCountry WITH (NOLOCK)
					WHERE CountryCode NOT IN (SELECT value FROM STRING_SPLIT(lp.BlockTargetCountry, ','))
				) AS t
			) As oam
		WHERE lp.IsDeleted = 0 AND ( oam.CountryCode = @TargetCountryCode OR @TargetCountryCode = '')
	)
	SELECT DISTINCT PageId, PageName, PageCode, OrderID
	FROM CTE_LandingPage
	ORDER BY OrderID ASC, PageId DESC
END
GO