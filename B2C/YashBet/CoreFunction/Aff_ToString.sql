/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_ToString] (
 @Value SQL_VARIANT
)
RETURNS NVARCHAR(4000)
AS
/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Convert a value to string for all data types
	
	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

*/
BEGIN	   
	RETURN CAST(ISNULL(@Value,'') AS NVARCHAR(4000))
END
GO