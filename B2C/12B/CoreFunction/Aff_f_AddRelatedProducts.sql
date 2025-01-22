/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_AddRelatedProducts]
(
	@ProductIds VARCHAR(MAX) = ''
)
RETURNS VARCHAR(MAX)
AS
/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Core function get related products

	Revisions:
		- 20241118@Eddie: Initialize Function [RedmineID: #212201]

*/
BEGIN
	DECLARE @ProductIdList VARCHAR(MAX)

	SELECT @ProductIdList = @ProductIds + 
		ISNULL(
				(SELECT ',' + CONVERT(VARCHAR(10), ProductId)
				FROM dbo.Aff_f_GroupProduct()
				WHERE ProductId <> GroupProductId
					AND CHARINDEX(',' + CONVERT(VARCHAR(10), GroupProductId) + ',', ',' + @ProductIds + ',') > 0
				FOR XML PATH(''))
			, '')
	
	RETURN @ProductIdList
END
