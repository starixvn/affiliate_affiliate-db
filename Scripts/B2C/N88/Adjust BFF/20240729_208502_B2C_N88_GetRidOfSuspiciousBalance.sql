/*<info serverAlias="DBAFFN88-Affiliate_N88"></info>*/
/*	
	Created: 20240729@Sally
	Task: N88 AFF - Get rid of suspicious balance [RedmineID: #208502]
	DB: DBAFFN88-Affiliate_N88
*/

USE Affiliate_N88
GO
------- Change SubComm----------
/*
SELECT *
FROM dbo.AffInfo ai WITH (NOLOCK)
WHERE ai.UserName = 'N88AFF1145'
;
SELECT *
FROM dbo.AffTrans with (nolock)
WHERE AffId = 1145
AND TransType = 204
AND TransDate  = '2024-06-30 00:00:00.000'
AND aft.Amount = 277.2100

*/
DECLARE @AffId		INT			= 1145
	,@TransDate		DATETIME	
	,@CompletedDate DATETIME	
	,@Amount		MONEY		
	,@Status		VARCHAR(50)	
	,@TransType		INT		
	,@AffCurrency	INT	
	,@AffRate		FLOAT	
	,@Description	NVARCHAR(300)
;
SELECT 
	@TransDate	= aft.TransDate
	,@CompletedDate = aft.CompletedDate
	,@Amount		= aft.Amount * (-1)
	,@Status		= aft.Status
	,@TransType		= aft.TransType
	,@AffCurrency	= aft.AffCurrency
	,@AffRate		= aft.AffRate
	,@Description   = aft.Description
FROM dbo.AffTrans aft WITH (NOLOCK)
WHERE AffId = @AffId
AND TransType = 204
AND TransDate  = '2024-06-30 00:00:00.000'
AND aft.Amount = 277.2100

INSERT INTO dbo.AffTrans (AffId, TransDate, CompletedDate, Amount, Status, Description, Creator, TransType, RefId, AffCurrency, AffRate)
	VALUES (@AffId, @TransDate, @CompletedDate, @Amount, @Status, @Description, 1, @TransType, NULL, @AffCurrency, @AffRate);
	

GO
--------------Adjust BFF--------------------
/*
SELECT *
FROM dbo.AffInfo ai WITH (NOLOCK)
WHERE ai.UserName = 'N88AFF2797'
;
SELECT at.AffId,		
	SUM(Amount) AS CurrentBBF		
FROM dbo.AffTrans at WITH (NOLOCK)
WHERE Status IN ('Pending', 'Approved', 'Completed')
	AND AffId = 2797
	AND transdate <'20240601'
GROUP BY AffId
;
*/

DECLARE @AffId		INT			= 2797
	,@TransDate		DATETIME	= '2024-05-31 00:00:00.000'
	,@CompletedDate DATETIME	= '2024-05-31 00:00:00.000'
	,@Amount		MONEY		
	,@Status		VARCHAR(50)	= 'Completed'
	,@TransType		INT		    = 203
	,@AffCurrency	INT			= 3
	,@AffRate		FLOAT		= 1
	,@Description	NVARCHAR(300) = 'Request adjust BFF'

SELECT @Amount = SUM(Amount) --  -1645.0980
FROM dbo.AffTrans at WITH (NOLOCK)
WHERE Status IN ('Pending', 'Approved', 'Completed')
	AND AffId = @AffId
	AND TransDate <'20240601'

-- SELECT @Amount

INSERT INTO dbo.AffTrans (AffId, TransDate, CompletedDate, Amount, Status, Description, Creator, TransType, RefId, AffCurrency, AffRate)
	VALUES (@AffId, @TransDate, @CompletedDate, @Amount, @Status, @Description, 1, @TransType, NULL, @AffCurrency, @AffRate);
