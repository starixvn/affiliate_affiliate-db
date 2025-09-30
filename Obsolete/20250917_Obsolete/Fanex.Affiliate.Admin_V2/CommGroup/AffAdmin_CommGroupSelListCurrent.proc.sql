ALTER PROCEDURE [dbo].[AffAdmin_CommGroup_SelActiveList] 
	@LicenseeID INT
	,@UserID		INT				= NULL
	,@Currency	VARCHAR(255)	= NULL
AS
/*
Created: 20140818@Bobby
Task : Get all active Commission Group List 
DB: DB052.Affiliate_Athena000
Original: Aff_CommGroupSelListNormal

Params Explaination:
   
Revisions:	
	- 20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site
	
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @TblCurrency TABLE (CurrencyID INT)

	SET @Currency = ISNULL(@Currency, '')

	INSERT INTO @TblCurrency (CurrencyID)
	SELECT AffCurrencyID AS CurrencyID
	FROM dbo.AffAdmin_f_UserCurrency_Select(@UserID, @LicenseeID)
	GROUP BY AffCurrencyID

	IF (@Currency <> 'All')
	BEGIN
		DELETE d
		FROM @TblCurrency d
		WHERE CurrencyID NOT IN (
				SELECT val
				FROM [dbo].[strSplit](@Currency, ',')
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

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroup_SelActiveList] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroup_SelActiveList] TO [vnteam]
GO
