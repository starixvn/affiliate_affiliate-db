/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_ProductSelAll]
	@Name VARCHAR(255) = NULL
AS

/*
	Created: 20130118@Joseph
	DB: DBAFF-Affiliate_Athena000

	Revisions:
		- 20140826@Bobby: add IsEnabled info
		- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]
		- 20211222@Percy: Merge SLT to SB [RedmineID: #165777]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @Name = '%' + ISNULL(RTRIM(LTRIM(@Name)), '') + '%'

	SELECT p.ProductID
		,p.ProductName
		,p.Description
		,p.CreatedDate
		,p.BettypeList
		,p.API_ProductID
		,p.Creator
		,p.CreatorName
		,p.IsEnabled
	FROM dbo.Product p WITH (NOLOCK)
		LEFT JOIN dbo.Aff_f_GroupProduct() g ON p.API_ProductId = g.API_ProductId AND g.API_ProductId <> g.GroupAPI_ProductId
	WHERE p.ProductName LIKE @Name
		AND g.API_ProductId IS NULL
END
GO