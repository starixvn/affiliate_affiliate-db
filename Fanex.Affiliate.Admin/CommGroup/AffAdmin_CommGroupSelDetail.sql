ALTER PROCEDURE [dbo].[AffAdmin_CommGroupSelDetail] 
	@GroupId	INT = NULL
	,@AffID		INT = NULL
AS
/*
Created: 20090719@DungTong
Task : Get Group Setting for Editing an existing Group
DB: DB052.Affiliate_MYM
Original:

Revisions:
	- 20140820@Bobby: Add Deposit & Withdrawal percent and apply SQL stylescope

*/
BEGIN
	SET NOCOUNT ON

	DECLARE @MonthDate SMALLDATETIME

	SET @MonthDate = CAST(GETDATE() AS DATE)

	IF @AffID IS NOT NULL
	BEGIN
		SELECT @GroupId = groupid
		FROM affinfo WITH (NOLOCK)
		WHERE affid = @AffID
	END

	SELECT cg.GroupID
		,cg.GroupName
		,cg.CreatedDate
		,cg.Creator
		,cg.[Description]
		,cg.Currency
		,cg.QualifiedAmount
		,(CASE 
			WHEN EXISTS (
					SELECT TOP (1) 1
					FROM dbo.AffCommission ac WITH(NOLOCK)
					WHERE ac.GroupID = cg.GroupID
					)
				OR EXISTS (
					SELECT TOP (1) 1
					FROM dbo.AffInfo ai WITH(NOLOCK)
					WHERE ai.GroupID = cg.GroupID
					) THEN 0
			ELSE 1 END
			) AS IsCurrencyEditable
		,ISNULL(cg.DepositPercent, ex.DepositPercent) AS DepositPercent
		,ISNULL(cg.WithdrawalPercent, ex.WithdrawalPercent) AS WithdrawalPercent
		,cb.HasCashback
	FROM dbo.CommGroup cg WITH(NOLOCK)
		INNER JOIN dbo.Exchange ex WITH (NOLOCK)
		ON cg.Currency = ex.ExchangeID
		CROSS APPLY ( 
			SELECT TOP 1 
				CASE 
					WHEN DATEDIFF(M, ISNULL(d.RemovedDate, GETDATE()), @MonthDate) <= 0 THEN 1 
					ELSE 0 
				END AS HasCashback  
			FROM [dbo].[DeductionType] d WITH(NOLOCK) 
			WHERE [ProductID] = 0  AND [DTypeName] = 'Cashback' 
		) cb
	WHERE cg.GroupID = @GroupID

	RETURN;

END
GO

GRANT EXECUTE ON [dbo].[AffAdmin_CommGroupSelDetail] TO [bodbAdminNet]
GO

GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CommGroupSelDetail] TO [vnteam]
