/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView,wsv_afinet,wsv_afinetv,wsv_aff,wsv_affv" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_AddRelatedProducts]
(
	@ProductIds VARCHAR(MAX) = ''
)
RETURNS VARCHAR(MAX)
AS
/*
	Created: 20241024@Sally
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Core function get related products

	Revisions:
		- 20241024@Sally: Initialize SP [RedmineID: #199895]

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
