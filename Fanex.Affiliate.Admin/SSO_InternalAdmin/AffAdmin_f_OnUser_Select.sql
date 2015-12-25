ALTER  FUNCTION  [dbo].[AffAdmin_f_OnUser_Select]
(		
	@IsKickedOut BIT
)
RETURNS @tbData TABLE
(
	On_UserID		INT,
	CustID			INT,
	Reload_Time		SMALLDATETIME,
	ServerID		INT,
	IP				VARCHAR(15),
	IsKickedOut		BIT,
	NetSessionID	VARCHAR(30)
) 
AS	
/*
Created:20151117@Victor
Task :  SSO from Internal Admin to Affiliate Admin
DB: DBAFF - Affiliate database

Revisions:
	- 20151224@Bobby: Add limit time range
	
Param's Explanation:

*/

BEGIN
	SET @IsKickedOut = ISNULL(@IsKickedOut, 0)

	INSERT INTO @tbData (On_UserID, CustID, Reload_Time, ServerID, IP, IsKickedOut, NetSessionID)
	SELECT On_UserID, CustID, Reload_Time, ServerID, IP, IsKickedOut, NetSessionID
	FROM DBLIC.bodb_licensee.dbo.Aff_On_User o WITH (NOLOCK) 
	WHERE IsKickedOut = @IsKickedOut
		AND reload_time >= dateadd(minute,-15,CURRENT_TIMESTAMP)

	RETURN
END

GO
GRANT SELECT ON [dbo].AffAdmin_f_OnUser_Select TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].AffAdmin_f_OnUser_Select TO [vnteam]


