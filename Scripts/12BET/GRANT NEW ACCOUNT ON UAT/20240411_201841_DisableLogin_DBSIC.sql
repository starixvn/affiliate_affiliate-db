/*<info serverAlias="DBSIC-CustDB,DBSIC-bodb02"></info>*/
/*
	Created: 20240411@Eddie
	DB: DBSIC-CustDB,bodb02
	Task: Disable login 'wsv_afinet' [Redmine: #201841]
*/

ALTER LOGIN [wsv_afinet]
DISABLE;
GO