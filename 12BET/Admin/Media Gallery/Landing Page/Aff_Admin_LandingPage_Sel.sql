/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_LandingPage_Sel]
	@PageId  SMALLINT = 0
	,@UserId INT = 0
AS

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Media Gallery - Landing Page - Select

	Revisions:
		- 20181001@Percy: Initialize SP [RedmineID: #102399]
		- 20191127@Percy: Sort by newest landing page [RedmineID: #118992]
		- 20221020@Eddie: Change order of Exchange & Sportsbook [RedmineID: #179392]
		- 20231106@Eddie: Change all order and show Excluded Target Country [RedmineID: #181590]
		- 20240820@Eddie: Change metadata "bodbAdminNet" [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON
	
	IF(@PageId <> 0)
	BEGIN
		;WITH CTE_LandingPage AS (  
			SELECT 
				lp.PageId
				,lp.PageName
				,lp.PageCode
				,lp.BlockTargetCountry AS ExcludedTargetCountry
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
			WHERE IsDeleted = 0 AND PageId = @PageId
		)  
		SELECT PageId, PageName, PageCode, ExcludedTargetCountry
		FROM CTE_LandingPage  
		ORDER BY OrderID ASC, PageId DESC
	END
	ELSE
	BEGIN
		;WITH CTE_LandingPage AS (  
			SELECT 
				lp.PageId
				,lp.PageName
				,lp.PageCode
				,ISNULL(oam.BlockTargetCountry, '') AS ExcludedTargetCountry
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
					SELECT STRING_AGG(t.CountryName, ', ') AS BlockTargetCountry
					FROM(
						SELECT tc.CountryName
						FROM dbo.UserMarket um WITH (NOLOCK)
							INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.MarketID = um.MarketId
							INNER JOIN STRING_SPLIT(lp.BlockTargetCountry, ',') s ON s.value = tc.CountryCode
						WHERE um.CustId = @UserId
						GROUP BY tc.CountryName
					) AS t
				) As oam
			WHERE IsDeleted = 0
		)
		SELECT PageId, PageName, PageCode, ExcludedTargetCountry
		FROM CTE_LandingPage
		ORDER BY OrderID ASC, PageId DESC
	END
END
GO