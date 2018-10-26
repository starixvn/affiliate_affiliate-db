USE [Affiliate_12BET]
GO

/*
	Created: 20181001@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Add new logs for Landing Page [RedmineID: #102322]
*/

DECLARE @TypeId SMALLINT

INSERT INTO dbo.LogType (TypeName, Description)
VALUES ('LandingPage', 'Landing Page')

SELECT @TypeId = SCOPE_IDENTITY()

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description)
SELECT 1001, @TypeId, 'Aff_Admin_LandingPage_Ins', 'Insert new landing page' UNION ALL
SELECT 1002, @TypeId, 'Aff_Admin_LandingPage_Upd', 'Update landing page' UNION ALL
SELECT 1003, @TypeId, 'Aff_Admin_LandingPage_Del', 'Delete landing page'