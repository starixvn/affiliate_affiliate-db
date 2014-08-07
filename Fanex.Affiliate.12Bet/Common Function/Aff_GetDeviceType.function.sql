ALTER FUNCTION [dbo].[Aff_GetDeviceType] (@DeviceType TINYINT)
RETURNS VARCHAR(100)
AS
/*
	Task : Get Device Type Name
	Author : 20140707@Bobby
	
*/
BEGIN
	DECLARE @TypeName VARCHAR(100)
	SELECT @TypeName = CASE 
			WHEN @DeviceType = 1 THEN 'Mobile'
			ELSE 'PC / Laptop'
			END

	RETURN @typename;
END
GO