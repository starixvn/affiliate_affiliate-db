/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250108@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #212201]
		2. Migrate BBF				

*/


USE Affiliate_12B
GO

DECLARE @TransType INT			= 203 -- Adjustment
	,@Description NVARCHAR(300) = 'Account balance carried forward from the previous system.' -- Input Here
	,@Creator	  INT			= 0
	,@TransDate	DATETIME		= GETDATE()
	,@Status VARCHAR(50)		= 'Completed'
	,@currentDate SMALLDATETIME

SELECT  @currentDate = CONVERT(DATE, GETDATE())

SELECT @Creator = CustId 
FROM Affiliate_User WITH (NOLOCK) 
WHERE UserName  =  'sa';

BEGIN TRY
	;WITH CTE_AFFInfo AS(
		SELECT ai.AffId
			,ai.Currency as AffCurrency
			,e.Rate AS AffRate		
		FROM dbo.AffInfo ai WITH (NOLOCK)
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ai.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@currentDate, ISNULL(t.ExchangeId, ai.Currency), 0) e
		WHERE ai.Status = 'Approved'
	)
	,CTE_BBFData AS (
		SELECT at.AffId
			,a.AffCurrency
			,a.AffRate
			,SUM(ISNULL(at.Amount,0)) AS BalBroughtForward
		FROM Affiliate_12BET.dbo.AffTrans at WITH (NOLOCK)
			INNER JOIN CTE_AFFInfo a WITH (NOLOCK) ON a.AffId = at.AffId
		WHERE at.status IN ('Approved', 'Pending', 'Completed')
		GROUP BY at.AffId
			,a.AffCurrency
			,a.AffRate
	)
		INSERT INTO Affiliate_12B.dbo.AffTrans
		(AffId, TransDate, CompletedDate, Amount, Status, Description, Creator, TransType, RefId, AffCurrency, AffRate)
		SELECT d.AffId, 
			@TransDate AS TransDate, 
			@TransDate AS CompletedDate, 
			d.BalBroughtForward AS Amount, 
			@Status AS Status, 
			@Description AS Description, 
			@Creator AS Creator, 
			@TransType TransType, 
			NULL AS RefId, 
			d.AffCurrency, 
			d.AffRate
		FROM CTE_BBFData d
		WHERE BalBroughtForward <> 0
END TRY
BEGIN CATCH

	TRUNCATE TABLE dbo.AffTrans
	SELECT 'Migrate BBF Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

END CATCH

--SELECT * from AffTrans

