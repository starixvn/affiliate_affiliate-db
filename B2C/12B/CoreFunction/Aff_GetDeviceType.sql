/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_GetDeviceType] (@DeviceType TINYINT)
RETURNS VARCHAR(100)
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task : Get Device Type Name

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
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