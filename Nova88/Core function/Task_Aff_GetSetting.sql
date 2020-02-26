/*<info serverAlias="DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_GetSetting]
	@SName VARCHAR(50)
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Core function get data in SystemSettings

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SELECT dbo.Aff_f_GetSetting(@SName) AS SValue
END
GO

GRANT EXECUTE ON [dbo].[Task_Aff_GetSetting] TO bodbAdminNet AS dbo
GO

GRANT EXECUTE ON [dbo].[Task_Aff_GetSetting] TO bodbDownlineNet AS dbo
GO

GRANT EXECUTE ON [dbo].[Task_Aff_GetSetting] TO bodbDownlineNetView AS dbo
GO