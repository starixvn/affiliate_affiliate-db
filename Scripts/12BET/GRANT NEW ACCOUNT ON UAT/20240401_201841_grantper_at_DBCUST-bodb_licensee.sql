/*<info serverAlias="DBCUST-bodb_licensee"></info>*/
/*
	Created: 20240328@Eddie
	DB: DBCUST-bodb_licensee
	Task: Grant permission for account 'wsv_afinet, wsv_afinetv' on UAT [Redmine: #201841]
*/
USE bodb_licensee
GO

GRANT SELECT ON [dbo].[LicenseeBAConfig] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerSetDefaultComm] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_CustomerUpdMemberComm] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeBAHistory] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[Licensees] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeCust] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeCustComm] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeUserFunctions] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeCurrencyBAGroup] TO [wsv_afinet]
GO
GRANT SELECT ON [dbo].[LicenseeSpecialCust] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBAHistoryIns] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBACustUpdComm] TO [wsv_afinet]
GO
GRANT EXECUTE ON [dbo].[Lrf_LicenseeBAHistoryUpdDone] TO [wsv_afinet]
GO