/*<info serverAlias="DBCUST-bodb_Licensee,DBLIC-bodb_Licensee" selecters="wsv_afinet" isFunction="1" isNested="1"></info>*/
USE [bodb_Licensee]
GO

ALTER FUNCTION [dbo].[AffAdmin_f_OnUser_Select]
(		
	@IsKickedOut BIT
)
RETURNS TABLE
AS

/*
	Created: 20151117@Victor
	Task: SSO from Internal Admin to Affiliate Admin
	DB: DBCUST.bodb_Licensee,DBLIC-bodb_Licensee

	Revisions:
		- 20190424@Percy: Move function to DBCUST.bodb_Licensee [RedmineID: #103658]
		- 20240808@Sally: Remove Linked server to DBCUST [RedmineID: #207020]
*/

RETURN
	SELECT On_UserID, CustID, Reload_Time, ServerID, IP, IsKickedOut, NetSessionID
	FROM dbo.Aff_On_User WITH (NOLOCK)
	WHERE IsKickedOut = ISNULL(@IsKickedOut, 0)
		AND reload_time >= DATEADD(MINUTE, -15, CURRENT_TIMESTAMP)
GO