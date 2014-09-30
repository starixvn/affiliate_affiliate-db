ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSelListNormal] 
	@UserID 	INT 			= NULL
	,@Currency 	VARCHAR(255) 	= NULL
AS
/*
Created: 20130903@Joseph
Task : Get Commission Group List (groupid<1000) for dropdown list
DB: DB052.Affiliate_MYM
Original:Aff_CommGroupSelListNormal

Params Explaination:
   if AffID<> -1: need to check whether this private group is already assigned to this Aff
   output : Change AffID=0 if existed
Revisions:	
	- 20130903@Joseph: Get NoCommission group (for all currency)
	- 20140704@Bobby: Include commgroup from CommGroupHistory
	- 20140818@Bobby: Standalize SP coding
*/
BEGIN
	SET NOCOUNT ON

	DECLARE @TblCurrency TABLE (CurrencyID INT)

	SET @Currency = ISNULL(@Currency, '')

	INSERT INTO @TblCurrency (CurrencyID)
	SELECT AttributeID AS CurrencyID
	FROM dbo.Aff_f_GetCurrencybyUser(@UserID, 1)
	GROUP BY AttributeID

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
	FROM dbo.CommGroup WITH (NOLOCK)
	WHERE GroupName = 'NoCommission'
	
	UNION
	SELECT cg.GroupId
		,cg.GroupName
	FROM dbo.CommGroup cg WITH (NOLOCK)
		INNER JOIN @TblCurrency tmp ON cg.Currency = tmp.CurrencyID
		LEFT JOIN dbo.CommGroupHistory ch WITH (NOLOCK) ON cg.GroupID = ch.GroupID
	WHERE cg.IsDeleted = 0
		OR (
			cg.IsDeleted = 1
			AND ch.IsDeleted = 0
			)
	GROUP BY cg.GroupId
		,cg.GroupName
END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelListNormal] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSelListNormal] TO [vnteam]
