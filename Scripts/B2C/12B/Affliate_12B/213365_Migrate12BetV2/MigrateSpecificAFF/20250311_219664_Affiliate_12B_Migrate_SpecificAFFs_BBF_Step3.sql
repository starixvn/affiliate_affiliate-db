/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250311@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Support new Aff 12B [RedmineId : #219664]
		2. Migrate BBF				

*/


USE Affiliate_12B
GO
--SELECT * from dbo.AffTrans
DECLARE @TransType INT			= 203 -- Adjustment
	,@Description NVARCHAR(300) = 'Account balance carried forward from the previous system.' 
	,@Creator	  INT			= 0
	,@TransDate	DATETIME		= GETDATE()
	,@Status VARCHAR(50)		= 'Completed'
	,@currentDate SMALLDATETIME
	,@AffIds NVARCHAR(MAX)		=  '92032696,92031306,92030078,92030041,1743135,2022200,1945887,927841,92040851,1282019,92030382,92036231,92036255,92031553,92029293,92029758,92030301,92036140,92041486,92040766,92031405,92029679,92034688,1749059,92042885'

SELECT  @currentDate = CONVERT(DATE, GETDATE())

SELECT @Creator = CustId 
FROM Affiliate_User WITH (NOLOCK) 
WHERE UserName  =  'sa';

DECLARE @AffId TABLE (AffId INT)
INSERT INTO  @AffId (AffId)
SELECT CONVERT(INT, value) as AffId
FROM STRING_SPLIT(@AffIds,',')

BEGIN TRY
	;WITH CTE_AFFInfo AS(
		SELECT ai.AffId
			,ai.Currency as AffCurrency
			,e.Rate AS AffRate		
		FROM dbo.AffInfo ai WITH (NOLOCK)
			INNER JOIN @AffId h ON h.AffId = ai.AffId
			LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ai.Currency = t.TpExchangeId
			CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(@currentDate, ISNULL(t.ExchangeId, ai.Currency), 0) e		
			 LEFT JOIN dbo.AffTrans at with (NOLOCK) ON at.AffId = ai.AffId AND at.TransType =  '203' and at.Description = 'Account balance carried forward from the previous system.'
		WHERE ai.Status = 'Approved'
			AND at.AffId IS NULL
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
		PRINT 'Migrate BBF Sucess!'

END TRY
BEGIN CATCH

	DELETE c 
	FROM dbo.AffTrans c  WITH(UPDLOCK, ROWLOCK)	
		INNER JOIN @AffId h ON h.AffId = c.AffId
	WHERE c.TransType =  '203' 
		AND c.Description = 'Account balance carried forward from the previous system.'
	SELECT 'Migrate BBF Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

END CATCH

