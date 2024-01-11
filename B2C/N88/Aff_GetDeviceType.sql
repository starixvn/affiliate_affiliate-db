/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_GetDeviceType] (@DeviceType TINYINT)
RETURNS VARCHAR(100)
AS
/*
	Task : Get Device Type Name
	Author: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G 
	
	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G [RedmineID: #128775]
*/
BEGIN
	DECLARE @TypeName VARCHAR(100)
	SELECT  @TypeName = CASE 
			WHEN @DeviceType = 1 THEN 'Mobile'
			ELSE 'PC / Laptop'
			END

	RETURN @TypeName;
END
GO