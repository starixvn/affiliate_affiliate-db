/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION dbo.Aff_f_GetSetting
(
	@SName VARCHAR(50)
)
RETURNS VARCHAR(200)
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function get data in SystemSettings

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]
*/

BEGIN
	DECLARE @SValue VARCHAR(200) = ''
	SELECT  @SValue = SValue FROM dbo.SystemSettings WITH (NOLOCK) WHERE SName = @SName
	
	RETURN @SValue
END
GO