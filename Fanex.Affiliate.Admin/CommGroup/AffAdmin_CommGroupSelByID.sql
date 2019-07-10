/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSelByID]		
	@LicenseeID		INT,
	@GroupID		INT,
	@UserId			INT,
	@UserCurrencies	VARCHAR(MAX) = ''
AS

/*
	Created: 20131114@Joseph
	Task : Search a Commission Group
	DB: DBAFF.Affiliate_XXX
	Original:

	Revisions:	
		- 20131121@Joseph: filter by TestLevel
		- 20151118@Victor: Implement SSO from Internal Admin to Affiliate Admin site
		- 20180208@Percy: Support Licensee Admin Portal [RedmineID: #90545]
		- 20190424@Percy: Change server of nested function [RedmineID: #103658]
							AffAdmin_f_IsITAdmin
*/

BEGIN
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX)
	SELECT  @sql = 'SELECT IsITAdmin FROM OPENQUERY(DBCUST, ''SELECT IsITAdmin FROM bodb_Licensee.dbo.AffAdmin_f_IsITAdmin('
																+ CONVERT(VARCHAR(20), @UserID) + ',' + CONVERT(VARCHAR(20), @LicenseeID) + ')'')'

	DECLARE @tblIsITAdmin TABLE (IsITAdmin BIT)
	INSERT INTO @tblIsITAdmin (IsITAdmin)
	EXEC (@sql)
	
	DECLARE @IsITAdmin BIT
	SELECT  @IsITAdmin = IsITAdmin FROM @tblIsITAdmin

	SELECT
		cg.GroupID,GroupName,Description,cg.CreatorName AS Creator
		,cg.CreatedDate,e.CurrencyID,e.CurrencyCode AS Currency,QualifiedAmount,
		Count(ai.AffID) AS NoOfAffiliate
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN dbo.Currency e ON cg.Currency = e.CurrencyID			  
		LEFT JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.GroupID = cg.GroupID
	WHERE 			   
		cg.GroupID = @GroupID
		AND (@IsITAdmin = 1 OR ai.TestLevel IN (0,1))
		AND (cg.Currency = 0 OR (cg.Currency IN (SELECT CONVERT(INT, val) FROM dbo.strSplit(@UserCurrencies, ','))))
	GROUP BY cg.GroupID, cg.GroupName,cg.Description,cg.CreatedDate,cg.QualifiedAmount,
		cg.CreatorName,e.CurrencyID,e.CurrencyCode
END
GO