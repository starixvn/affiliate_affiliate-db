/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="1" isNested="1"></info>*/
ALTER FUNCTION [dbo].[Aff_f_AddRelatedProducts]
(
	@ProductIds VARCHAR(MAX) = ''
)
RETURNS VARCHAR(MAX)
AS
/*
	Created: 20240222@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Core function get related products

	Revisions:
		- 20240222@Sally: Initialize SP [RedmineID: #199895]

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
