/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_ToString] (
 @Value SQL_VARIANT
)
RETURNS NVARCHAR(4000)
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Convert a value to string for all data types
	
	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/
BEGIN	   
	RETURN CAST(ISNULL(@Value,'') AS NVARCHAR(4000))
END
GO