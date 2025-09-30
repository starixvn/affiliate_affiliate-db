/*
	Task : 12Bet - EU migration: Insert EU member (player) information  - Batch 2
	Author : Bobby.Nguyen@20140124
	DB: Affiliate_12Bet
*/

USE [Affiliate_12BET];
GO

IF ( NOT EXISTS (
		SELECT TOP 1 1
		FROM sys.sysObjects o
		WHERE o.NAME = 'EUAffPlayers') 
	) 
BEGIN
	PRINT 'Not found dependencies'
	RETURN;
END


--delete [MemberImport_Log]
IF (
		EXISTS (
			SELECT 1
			FROM sys.sysObjects o
			WHERE o.NAME = 'MemberImport_Log'
			)
		) DROP TABLE [dbo].[MemberImport_Log];
GO

DECLARE @MemberOutput TABLE(IBCCustID INT, AffID INT, EUAction varchar(50))

;WITH MemImport AS (
	SELECT eu.*
		, aff.AffID
		, CAST(GETDATE() AS DATE) AS AffAffectedDate
		, 0 AS IsRemoved
	FROM dbo.EUAffPlayers eu WITH(NOLOCK)
	LEFT JOIN dbo.AffInfo aff 
		ON eu.EUAffID = aff.EUAffID
	WHERE eu.IBCCustID > 0
		AND aff.AffID > 0
		AND (eu.[BatchNo] = 2 OR eu.EUAffID = 1)
)
MERGE INTO dbo.MemberInfo AS mem 
USING MemImport AS eu
	ON eu.IBCCustID = mem.IBCCustID
WHEN NOT MATCHED BY TARGET THEN
	INSERT ([IBCCustID]
	    ,[AffID]
	    ,[UserName]
	    ,[IBCUserName]
	    ,[CreatedDate]
	    ,[RegisteredDate]
	    ,[IsRemoved]
	    ,[DepositCustID]
	    ,[FirstName]
	    ,[LastName]
	    ,[Currency]
	    ,[Email]
	    ,[Recommend]
	    ,[ClickId]
	    ,[AffAffectedDate]
	    ,[EUAffID])
	VALUES(eu.IBCCustID	
		,eu.AffID			
		,eu.UserName		
		,eu.IBCUserName	
		,eu.FirstDepositDate
		,eu.RegisteredDate	
		,eu.IsRemoved
		,eu.DepositCustID
		,eu.FirstName	
		,eu.LastName	
		,eu.Currency	
		,eu.Email		
		,eu.Recommend
		,eu.ClickID
		,eu.AffAffectedDate
		,eu.EUAffID)

	--WHEN MATCHED THEN

	OUTPUT Inserted.IBCCustID	
		, Inserted.AffID, $Action 
INTO @MemberOutput(IBCCustID, AffID, EUAction);

SELECT * 
INTO MemberImport_Log
FROM @MemberOutput

SELECT * FROM MemberImport_Log

GO

