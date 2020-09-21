/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION dbo.Aff_f_GetSetting
(
	@SName VARCHAR(50)
)
RETURNS VARCHAR(200)
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Core function get data in SystemSettings

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	DECLARE @SValue VARCHAR(200) = ''
	SELECT  @SValue = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = @SName
	
	RETURN @SValue
END
GO