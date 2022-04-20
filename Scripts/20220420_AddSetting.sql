/*<info serverAlias="DBAFF-Affiliate_9Bet,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/

/*
	Created: 20220420@Malcolm
	DB: DBAFF-Affiliate_Athena000,DBAFF-Affiliate_9Bet,DBAFF-Affiliate_Aoncash,DBAFF-Affiliate_ItcBet,DBAFF-Affiliate_MacauBet,DBAFF-Affiliate_Spondemo
	Task: add setting [RedmineID: #171766]
*/
INSERT INTO dbo.SystemSettings (Type,SName,SValue,Description,Environment)
SELECT Type,SName,SValue,Description,Environment
FROM (
	VALUES 
		('Meta', 'AFF_DefaultCommGroup', 'NoCommission', NULL, 'Production')
		,('Meta', 'AFF_DefaultCommGroup', 'NoCommission', NULL, 'UAT')
) AS n(Type,SName,SValue,Description,Environment)
WHERE NOT EXISTS (
	SELECT 1 
	FROM dbo.SystemSettings s WITH(NOLOCK) 
	WHERE s.SName = n.SName AND s.Environment = n.Environment
)