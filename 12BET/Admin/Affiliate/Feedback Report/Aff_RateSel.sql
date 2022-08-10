/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbDownlineNet,bodbDownlineNetView" viewers="" isFunction="0" isNested="1"></info>*/
CREATE PROCEDURE [dbo].[Aff_RateSel]
AS
	/*
	Created: 20220802@Eddie
	DB: DBAFF12BET.Affiliate_12BET
	Task : User site - Contact Us - get Rate
	
	Revisions:
		- 20220802@Eddie: Initialize SP [RedmineID: #175628]
	*/
SET NOCOUNT ON

-- 'None' when the user only sends a message and does not choose an emoji.           
SELECT 0  AS [Rateid], 'None' 	 		  AS [RateName]
UNION ALL                        
SELECT 1  AS [Rateid], 'Dissatisfaction'  AS [RateName]
UNION ALL                        
SELECT 2  AS [Rateid], 'Unsatisfied'      AS [RateName]
UNION ALL
SELECT 3  AS [Rateid], 'Neutral' 		  AS [RateName]
UNION ALL
SELECT 4  AS [Rateid], 'Satisfied' 		  AS [RateName]
UNION ALL
SELECT 5  AS [Rateid], 'Very Pleased' 	  AS [RateName]

GO