/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20231114@Eddie
	DB: DBAFF12BET-Affiliate_12BET
	Task: Add new column NoteType[RedmineId : #195391]
*/
-- Note: NoteType = 0 (note) and NoteType = 1 (marketing team note)
ALTER TABLE dbo.AdminNotes
	ADD NoteType BIT NOT NULL CONSTRAINT [DF_AdminNotes_NoteType] DEFAULT (0)
GO