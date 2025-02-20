/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250220@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Migrate Email History [RedmineID: #212201]
		-  Scope migrate note data:
		+ All data from Jan 2024

*/
USE Affiliate_12B
GO

DECLARE @FromDate DATETIME  = '2024-01-01'
	
BEGIN TRY
	PRINT 'Inserting EmailHistory'

	INSERT INTO [dbo].[EmailHistory]
           ([Content]
           ,[Sender]
           ,[Creator]
           ,[AffId]
           ,[AffName]
           ,[Email]
           ,[Subject]
           ,[CreatedDate]
           ,[IP]
           ,[Browser]
           ,[SessionId]
           ,[IsDeleted]
	)
		SELECT a.[Content]
           ,a.[Sender]
           ,a.[Creator]
           ,a.[AffId]
           ,a.[AffName]
           ,a.[Email]
           ,a.[Subject]
           ,a.[CreatedDate]
           ,a.[IP]
           ,a.[Browser]
           ,a.[SessionId]
           ,a.[IsDeleted]
		FROM Affiliate_12BET.dbo.[EmailHistory] a WITH (NOLOCK)
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = a.AffID
		WHERE a.CreatedDate >= @FromDate
			AND a.IsDeleted = 0

	PRINT 'Migrate EmailHistory Success!'
END TRY
BEGIN CATCH	
	TRUNCATE TABLE Affiliate_12B.dbo.[EmailHistory]
	SELECT 'Migrate EmailHistory Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH



