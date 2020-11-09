/*<info serverAlias="DBN88-bodb_N88"></info>*/

/*
	Created: 20201109@Percy
	DB: DBN88-bodb_N88
	Task: Add new column: FirstDepositDate, FirstDepositAmount to get FDM value
*/

use bodb_N88
go

alter table dbo.Customer
	add FirstDepositDate datetime
		,FirstDepositAmount money
go