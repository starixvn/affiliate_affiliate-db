/*<info serverAlias="DBAFF-Affiliate_Athena000" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_Athena000]
GO

ALTER PROCEDURE [dbo].[AffAdmin_CommGroup_SelActiveList] 
	@UserCurrencies	VARCHAR(MAX) = '',
	@Currencies		VARCHAR(255) = ''
AS

/*
Created: 20140818@Bobby
Task : Get all active Commission Group List 
DB: DB052.Affiliate_Athena000
Original: Aff_CommGroupSelListNormal

Params Explaination:
   
Revisions:	
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	- 20180205@Percy: Replace @UserId, @LicenseeId to @UserCurrencies to get list of currencies [RedmineID: #90545]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @TblCurrency TABLE (CurrencyID INT)

	SET @Currencies = ISNULL(@Currencies, '')

	INSERT INTO @TblCurrency (CurrencyID)
	SELECT val
	FROM dbo.strSplit(@UserCurrencies, ',')

	IF (@Currencies <> 'All')
	BEGIN
		DELETE d
		FROM @TblCurrency d
		WHERE CurrencyID NOT IN (
				SELECT val
				FROM [dbo].[strSplit](@Currencies, ',')
				)
	END

	-- fecth commgroup info
	SELECT GroupId
		,GroupName
	FROM (
		SELECT GroupId
			,GroupName
		FROM dbo.CommGroup WITH (NOLOCK)
		WHERE GroupName = 'NoCommission'
		
		UNION
		SELECT cg.GroupId
			,cg.GroupName
		FROM dbo.CommGroup cg WITH (NOLOCK)
			INNER JOIN @TblCurrency tmp ON cg.Currency = tmp.CurrencyID
		WHERE cg.IsDeleted = 0
		GROUP BY cg.GroupId
			,cg.GroupName
	) t
	ORDER BY GroupId
END
GO