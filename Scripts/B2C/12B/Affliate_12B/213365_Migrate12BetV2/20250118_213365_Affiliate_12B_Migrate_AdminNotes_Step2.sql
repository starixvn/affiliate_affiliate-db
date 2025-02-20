/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Created: 20250219@Sally
	DB: DBAFF12B-Affiliate_12B
	Task: Add new permission: Note, MarketingTeamNote [RedmineID: #212201]
		-  scope migrate note data:
		+ All marketing note created by AAmaggie pls carry on under "Note"
		+ For "marketing note"all notes created by following user in old backend pls carry on

*/

USE Affiliate_12B
GO

DECLARE @User_Mapping TABLE(
	UserId_V1 INT,
	UserName_V1 VARCHAR (50),
	UserId_V2 INT,
	UserName_V2 VARCHAR (30)

)

;WITH CTE_MigrateInfo AS (
	SELECT 'AAmaggie' As User_V1, 'AAmaggie' as User_V2 UNION ALL
	SELECT 'aaabhi' As User_V1, 'aaabhinavauv' as User_V2 UNION ALL
	SELECT 'aamelvyn' As User_V1, 'aamelvynmn' as User_V2 UNION ALL
	SELECT 'aakenny' As User_V1, 'aakennytkk' as User_V2 UNION ALL
	SELECT 'aasora' As User_V1, 'aasoratnp' as User_V2 UNION ALL
	SELECT 'aaphoenix' As User_V1, 'aaphoenixlpk' as User_V2 UNION ALL
	SELECT 'aawhite' As User_V1, 'aawhitenp' as User_V2 UNION ALL
	SELECT 'aajin' As User_V1, 'aajin' as User_V2 UNION ALL
	SELECT 'aasendy' As User_V1, 'aaabhinavauv' as User_V2 UNION ALL
	SELECT 'aavijay' As User_V1, 'aavijayvmj' as User_V2 UNION ALL
	SELECT 'aakumar' As User_V1, 'aaabhinavauv' as User_V2 UNION ALL
	SELECT 'aaarie' As User_V1, 'aaariedap' as User_V2 UNION ALL
	SELECT 'aaken' As User_V1, 'aathaikenn' as User_V2 
)
INSERT INTO @User_Mapping( UserId_V1, UserName_V1, UserName_V2)
SELECT u.CustId, u.UserName, uc.User_V2 as UserName_V2
FROM Affiliate_12BET.dbo.Users u  WITH (NOLOCK) 
	INNER JOIN CTE_MigrateInfo uc on uc.User_V1 = u.UserName

UPDATE uc SET UserId_V2 = u.CustId
FROM @User_Mapping uc
	INNER JOIN Affiliate_12B.dbo.Affiliate_User u  WITH (NOLOCK) ON  uc.UserName_V2 = u.UserName
	
BEGIN TRY

	PRINT 'Inserting AdminNotes AAmaggie'
	SET IDENTITY_INSERT dbo.AdminNotes ON;

	-- All marketing note created by AAmaggie pls carry on under "Note"
	INSERT INTO dbo.AdminNotes (NoteId, AffID, Note, UpdatedBy, UpdatedDate, NoteType)
		SELECT a.NoteId, a.AffID, a.Note,u.UserId_V2 AS UpdatedBy, a.UpdatedDate, 0 AS NoteType
		FROM Affiliate_12BET.dbo.AdminNotes a WITH (NOLOCK)
			INNER JOIN @User_Mapping u ON u.UserId_V1 = a.UpdatedBy AND u.UserName_V1 = 'AAmaggie'
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = a.AffID

	 --- For "marketing note"all notes created by following user in old backend pls carry on
	PRINT 'Inserting Marking Note'
	INSERT INTO dbo.AdminNotes (NoteId, AffID, Note, UpdatedBy, UpdatedDate, NoteType)
		SELECT a.NoteId, a.AffID, a.Note,u.UserId_V2 AS UpdatedBy, a.UpdatedDate, 1 AS NoteType
		FROM Affiliate_12BET.dbo.AdminNotes a WITH (NOLOCK)
			INNER JOIN @User_Mapping u ON u.UserId_V1 = a.UpdatedBy AND u.UserName_V1 <> 'AAmaggie'
			INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = a.AffID
	SET IDENTITY_INSERT dbo.AdminNotes OFF;

	PRINT 'Migrate AdminNotes Success!'
END TRY
BEGIN CATCH
	SET IDENTITY_INSERT dbo.AdminNotes OFF;
	TRUNCATE TABLE Affiliate_12B.dbo.AdminNotes
	SELECT 'Migrate AdminNotes Fail!' AS [Status], ERROR_NUMBER() AS ErrorNumber, ERROR_MESSAGE() AS ErrorMessage;
END CATCH



