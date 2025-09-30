/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_ProductSelAll] 
	@Name VARCHAR(255) = NULL
AS

/*
Created: 20130118@Joseph
Task : Get All Countries From System
DB: DB052.Affiliate_MYM
Original:AffAdmin_ProductSelAll

Revisions:
	- 20140826@Bobby: add IsEnabled info
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]

Param's Explanation (filtered by):

*/
BEGIN
	SET NOCOUNT ON

	SELECT @Name = '%' + ISNULL(RTRIM(LTRIM(@Name)), '') + '%'

	SELECT c.ProductID
		,c.ProductName
		,c.Description
		,c.CreatedDate
		,c.BettypeList
		,c.API_ProductID
		,c.Creator
		,c.CreatorName
		,c.IsEnabled
	FROM dbo.Product C WITH (NOLOCK)
	WHERE ProductName LIKE @Name
END
GO