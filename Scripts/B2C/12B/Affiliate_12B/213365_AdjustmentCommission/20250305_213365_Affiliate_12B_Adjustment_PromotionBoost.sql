/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250305@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Adjustment BBF- Commission Feb 2025 [RedmineID: #212201]
        - Template 2:  Adjustment - Promotion boost
*/
USE Affiliate_12B;
GO

DECLARE @TransType INT = 203 -- Adjustment
    ,@Description NVARCHAR(300) = 'Adjustment - Promotion boost' 
    ,@Creator INT = 0
    ,@TransDate DATETIME = GETDATE()
    ,@Status VARCHAR(50) = 'Completed'
    ,@currentDate SMALLDATETIME
	,@AffRate FLOAT = 0
	,@AffCurrency INT = 3;

SELECT  @currentDate =  CONVERT(DATE, GETDATE())

SELECT @Creator = CustId 
FROM Affiliate_User WITH (NOLOCK) 
WHERE UserName  =  'sa';

SELECT @AffRate =  e.Rate
FROM dbo.Aff_f_ExchangeRate_Sel(@currentDate, @AffCurrency, 0) e	

CREATE TABLE #Adjustment_Data (AffId INT, Username VARCHAR(30), Amount MONEY)
;WITH CTE_AFFInfo AS(
	SELECT '12BETAFF130' AS Username, 192.6 as Amount UNION ALL
	SELECT '12BETAFF15141' AS Username, 117.05 as Amount UNION ALL
	SELECT '12BETAFF8267' AS Username, 250 as Amount UNION ALL
	SELECT '12BETAFF13866' AS Username, 500 as Amount UNION ALL
	SELECT '12BETAFF14885' AS Username, 2000 as Amount UNION ALL
	SELECT '12BETAFF3519' AS Username, 500 as Amount UNION ALL
	SELECT '12BETAFF12430' AS Username, 116.73 as Amount UNION ALL
	SELECT '12BETAFF15932' AS Username, 7.08 as Amount UNION ALL
	SELECT '12BETAFF11843' AS Username, 500 as Amount UNION ALL
	SELECT '12BETAFF13697' AS Username, 35.78 as Amount
	)
INSERT INTO #Adjustment_Data(AffId, Username, Amount)
SELECT ISNULL(ai.AffId, ai_v1.AffId) AS AffId, ISNULL(ai.UserName, ai_v1.UserName) AS UserName, CONVERT(MONEY, REPLACE(Amount, ',', '')) AS Amount
FROM CTE_AFFInfo a
	LEFT JOIN dbo.AffInfo ai WITH(NOLOCK) ON a.Username = ai.UserName
	INNER JOIN Affiliate_12BET.dbo.AffInfo ai_v1 WITH(NOLOCK) ON ai_v1.Username = a.UserName
WHERE ISNULL(ai.status,ai_v1.status) = 'Approved'

BEGIN TRY
		INSERT INTO Affiliate_12B.dbo.AffTrans
		(AffId, TransDate, CompletedDate, Amount, Status, Description, Creator, TransType, RefId, AffCurrency, AffRate)
		SELECT d.AffId, 
			@TransDate AS TransDate, 
			@TransDate AS CompletedDate, 
			d.Amount AS Amount, 
			@Status AS Status, 
			@Description AS Description, 
			@Creator AS Creator, 
			@TransType TransType, 
			NULL AS RefId, 
			@AffCurrency, 
			@AffRate
		FROM #Adjustment_Data d

		PRINT 'Migrate BBF Sucess!'

END TRY
BEGIN CATCH

	DELETE c 
	FROM dbo.AffTrans c  WITH(UPDLOCK, ROWLOCK)	
		INNER JOIN #Adjustment_Data h ON h.AffId = c.AffId
	WHERE c.TransType =  '203' 
		AND c.Description = 'Adjustment - Promotion boost'
		AND c.Creator = @Creator

	SELECT 'Migrate BBF Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

END CATCH



