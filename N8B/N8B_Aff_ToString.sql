/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_ToString] (
 @Value sql_variant
)
RETURNS nvarchar(4000)
AS
/*
	DB: DBAFFN8B-Affiliate_N8B
	Task: Convert a value to string for all data types
	
	Revisions:
		- 20200220@Percy: Initialize SP for DBAFFN8B-Affiliate_N8B [RedmineID: #128775]
*/
BEGIN	   
	return cast(isnull(@Value,'') as nvarchar(4000))
END
GO