/*<info serverAlias="DBLIC-bodb_Licensee"></info>*/
/*	
	Created: 20240802@Sally
	Task: Remove linked server to DBCust 206891 [RedmineID: #206891]
	DB: DBLIC-bodb_Licensee
	- Grant permission SELECT  for 'wsv_afinet' Account
*/

USE bodb_Licensee
GO

CREATE USER [wsv_afinet] FOR LOGIN [wsv_afinet] WITH DEFAULT_SCHEMA=[dbo]
GO

GRANT SELECT ON [dbo].[Users] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_LicenseeUser] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_GroupInfo] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_On_User] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_FunctionInfo] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_UserPolicy] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_GroupPolicy] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Aff_LicenseeFunction] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[Systems] TO [wsv_afinet]
GO

GRANT SELECT ON [dbo].[CurrencyUser] TO [wsv_afinet]
GO
