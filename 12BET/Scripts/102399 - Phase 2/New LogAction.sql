INSERT INTO dbo.LogType (TypeName, Description)
VALUES ('LandingPage', 'Landing Page')

INSERT INTO dbo.LogAction (ActionId, ActionTypeId, SPName, Description)
SELECT 1001, 21, 'Aff_Admin_LandingPage_Ins', 'Insert new landing page' UNION ALL
SELECT 1002, 21, 'Aff_Admin_LandingPage_Upd', 'Update landing page' UNION ALL
SELECT 1003, 21, 'Aff_Admin_LandingPage_Del', 'Delete landing page'
