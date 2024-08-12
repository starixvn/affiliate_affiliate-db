/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_GetSystemSettings]
	@SName VARCHAR(50)
AS

/*
	Created: 20240722@Sally
	DB: DBAFF-Affiliate_Athena000
	Task: Remove linked server to DBCust 

	Revisions:
		- 20240722@Sally: Initialize SP [RedmineID: #206891]

*/   
BEGIN
	SET NOCOUNT ON
	
	SELECT ss.SName, ss.SValue, ss.Type
	FROM dbo.SystemSettings ss WITH (NOLOCK)
	WHERE ss.SName = @SName

END
