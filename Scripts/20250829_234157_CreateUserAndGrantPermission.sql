/*<info serverAlias="DBCUST-IPDB"></info>*/
/*
	Created: 20250829@Danny
	DB: DBCUST-IPDB
	Task: Create User and grant permission
*/
USE IPDB
GO

CREATE USER [wsv_afinet] FOR LOGIN [wsv_afinet] WITH DEFAULT_SCHEMA=[dbo]

--GRANT EXECUTE ON Acc_GetIPInfo_Full  TO wsv_afinet