/*<info serverAlias="DBN88-bodb_N88"></info>*/

/*
	Created: 20201109@Percy
	DB: DBN88-bodb_N88
	Task: Add new column: FirstDepositDate, FirstDepositAmount to get FDM value
*/

use bodb_N88
go

-- 3711 rows
update c with (rowlock)
set c.FirstDepositDate = d.CreateTime
	,c.FirstDepositAmount = d.Amount
from dbo.Customer c
	inner join dbo.DepositInfo d with (nolock) on c.CustId = d.CustId
where d.FirstDeposit = 1