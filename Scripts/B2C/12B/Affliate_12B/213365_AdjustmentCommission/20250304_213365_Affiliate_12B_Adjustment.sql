/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250303@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Adjustment BBF- Commission Feb 2025 [RedmineID: #212201]
        - Template 1:  Adjustment - Commission of Feb.2025
        - Template 2:  Adjustment - Promotion boost
*/
USE Affiliate_12B;
GO

DECLARE @TransType INT = 203 -- Adjustment
    ,@Description NVARCHAR(300) = 'Adjustment - Commission of Feb.2025' 
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
	SELECT '12BETAFF130' AS Username, 6420.01 as Amount UNION ALL
	SELECT '12BETAFF15141' AS Username, 2341.01 as Amount UNION ALL
	SELECT '12BETAFF8267' AS Username, 46590.9 as Amount UNION ALL
	SELECT '12BETAFF13554' AS Username, 43338.17 as Amount UNION ALL
	SELECT '12BETAFF14326' AS Username, 18532.28 as Amount UNION ALL
	SELECT '12BETAFF13866' AS Username, 23149.23 as Amount UNION ALL
	SELECT '12BETAFF14885' AS Username, 28327.11 as Amount UNION ALL
	SELECT '12BETAFF3519' AS Username, 25394.19 as Amount UNION ALL
	SELECT '12BETAFF13685' AS Username, 13431.07 as Amount UNION ALL
	SELECT '12BETAFF11417' AS Username, 8416.28 as Amount UNION ALL
	SELECT '12BETAFF226' AS Username, 7812.37 as Amount UNION ALL
	SELECT '12BETAFF14351' AS Username, 7338.95 as Amount UNION ALL
	SELECT '12BETAFF1920' AS Username, 4251.19 as Amount UNION ALL
	SELECT '12BETAFF2590' AS Username, 4910.68 as Amount UNION ALL
	SELECT '12BETAFF13972' AS Username, 1960.6 as Amount UNION ALL
	SELECT '12BETAFF15154' AS Username, 11342.47 as Amount UNION ALL
	SELECT '12BETAFF2961' AS Username, 6327.25 as Amount UNION ALL
	SELECT '12BETAFF3326' AS Username, 6713.82 as Amount UNION ALL
	SELECT '12BETAFF371' AS Username, 6281.93 as Amount UNION ALL
	SELECT '12BETAFF3618' AS Username, 9606.35 as Amount UNION ALL
	SELECT '12BETAFF12620' AS Username, 12951.92 as Amount UNION ALL
	SELECT '12BETAFF7216' AS Username, 1900.06 as Amount UNION ALL
	SELECT '12BETAFF12430' AS Username, 2334.69 as Amount UNION ALL
	SELECT '12BETAFF14310' AS Username, 1958.7 as Amount UNION ALL
	SELECT '12BETAFF078' AS Username, 1282.09 as Amount UNION ALL
	SELECT '12BETAFF2758' AS Username, 863.36 as Amount UNION ALL
	SELECT '12BETAFF2901' AS Username, 3140.4 as Amount UNION ALL
	SELECT '12BETAFF14275' AS Username, 1070.85 as Amount UNION ALL
	SELECT '12BETAFF8034' AS Username, 1361.06 as Amount UNION ALL
	SELECT '12BETAFF7824' AS Username, 2078.73 as Amount UNION ALL
	SELECT '12BETAFF1051' AS Username, 686.59 as Amount UNION ALL
	SELECT '12BETAFF7889' AS Username, 636.91 as Amount UNION ALL
	SELECT '12BETAFF3961' AS Username, 16.21 as Amount UNION ALL
	SELECT '12BETAFF14031' AS Username, 1240.26 as Amount UNION ALL
	SELECT '12BETAFF3475' AS Username, 13007.91 as Amount UNION ALL
	SELECT '12BETAFF593' AS Username, 5577.48 as Amount UNION ALL
	SELECT '12BETAFF2554' AS Username, 2769.24 as Amount UNION ALL
	SELECT '12BETAFF4738' AS Username, 888.61 as Amount UNION ALL
	SELECT '12BETAFF13300' AS Username, 1327.18 as Amount UNION ALL
	SELECT '12BETAFF14553' AS Username, 411.07 as Amount UNION ALL
	SELECT '12BETAFF3380' AS Username, 750.77 as Amount UNION ALL
	SELECT '12BETAFF15390' AS Username, 405.39 as Amount UNION ALL
	SELECT '12BETAFF5381' AS Username, 1086.01 as Amount UNION ALL
	SELECT '12BETAFF14477' AS Username, 1602.77 as Amount UNION ALL
	SELECT '12BETAFF1561' AS Username, 875.54 as Amount UNION ALL
	SELECT '12BETAFF13512' AS Username, 313.2 as Amount UNION ALL
	SELECT '12BETAFF16155' AS Username, 445.92 as Amount UNION ALL
	SELECT '12BETAFF13815' AS Username, 648.08 as Amount UNION ALL
	SELECT '12BETAFF14539' AS Username, 238.92 as Amount UNION ALL
	SELECT '12BETAFF4900' AS Username, 3863.7 as Amount UNION ALL
	SELECT '12BETAFF1432' AS Username, 210.87 as Amount UNION ALL
	SELECT '12BETAFF3158' AS Username, 404.27 as Amount UNION ALL
	SELECT '12BETAFF14380' AS Username, 638.92 as Amount UNION ALL
	SELECT '12BETAFF1992' AS Username, 158.36 as Amount UNION ALL
	SELECT '12BETAFF11954' AS Username, 261.95 as Amount UNION ALL
	SELECT '12BETAFF14046' AS Username, 102.23 as Amount UNION ALL
	SELECT '12BETAFF15932' AS Username, 236.02 as Amount UNION ALL
	SELECT '12BETAFF13902' AS Username, 3398.94 as Amount UNION ALL
	SELECT '12BETAFF12569' AS Username, 8982.83 as Amount UNION ALL
	SELECT '12BETAFF792' AS Username, 2550.2 as Amount UNION ALL
	SELECT '12BETAFF2646' AS Username, 1725.28 as Amount UNION ALL
	SELECT '12BETAFF12508' AS Username, 1764.25 as Amount UNION ALL
	SELECT '12BETAFF13610' AS Username, 574.28 as Amount UNION ALL
	SELECT '12BETAFF12800' AS Username, 1693.39 as Amount UNION ALL
	SELECT '12BETAFF7666' AS Username, 549.92 as Amount UNION ALL
	SELECT '12BETAFF11843' AS Username, 20047.29 as Amount UNION ALL
	SELECT '12BETAFF12831' AS Username, 437.21 as Amount UNION ALL
	SELECT '12BETAFF13697' AS Username, 715.69 as Amount UNION ALL
	SELECT '12BETAFF15002' AS Username, -212.25 as Amount UNION ALL
	SELECT '12BETAFF7782' AS Username, -595.94 as Amount UNION ALL
	SELECT '12BETAFF14719' AS Username, -320.98 as Amount UNION ALL
	SELECT '12BETAFF14327' AS Username, -8231.4 as Amount UNION ALL
	SELECT '12BETAFF12716' AS Username, -490.68 as Amount UNION ALL
	SELECT '12BETAFF643' AS Username, -684.74 as Amount UNION ALL
	SELECT '12BETAFF11384' AS Username, -5408.58 as Amount UNION ALL
	SELECT '12BETAFF14617' AS Username, -2030.61 as Amount UNION ALL
	SELECT '12BETAFF2654' AS Username, -288.12 as Amount UNION ALL
	SELECT '12BETAFF2233' AS Username, -47650.48 as Amount  
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
		AND c.Description = 'Adjustment - Commission of Feb.2025'
		AND c.Creator = @Creator

	SELECT 'Migrate BBF Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;

END CATCH



