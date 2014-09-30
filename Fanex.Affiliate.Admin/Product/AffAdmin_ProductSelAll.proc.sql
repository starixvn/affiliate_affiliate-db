ALTER PROCEDURE [dbo].[AffAdmin_ProductSelAll] 
	@Name VARCHAR(255) = NULL
AS
/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:AffAdmin_ProductSelAll

Revisions:
	-20140826@Bobby: add IsEnabled info

Param's Explanation (filtered by):

*/
BEGIN
	SET NOCOUNT ON

	SELECT @Name = '%' + ISNULL(RTRIM(LTRIM(@Name)), '') + '%'

	SELECT ProductID
		,ProductName
		,Description
		,au.custid AS Creator
		,ISNULL(au.username, 'System') AS CreatorName
		,CreatedDate
		,BettypeList
		,API_ProductID
		,IsEnabled
	FROM (
		SELECT c.ProductID
			,c.ProductName
			,c.Description
			,c.CreatedDate
			,c.BettypeList
			,c.API_ProductID
			,c.Creator
			,c.IsEnabled
		FROM dbo.Product C WITH (NOLOCK)
		WHERE ProductName LIKE @Name
		) x
		LEFT JOIN dbo.AdminUser au ON x.Creator = au.custid
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ProductSelAll] TO [bodbAdminNet] AS [dbo]
GO