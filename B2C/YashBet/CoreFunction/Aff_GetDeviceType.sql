/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_GetDeviceType] (@DeviceType TINYINT)
RETURNS VARCHAR(100)
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task : Get Device Type Name

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]
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