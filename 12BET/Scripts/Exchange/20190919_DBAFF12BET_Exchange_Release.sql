use Affiliate_12BET
go

/*
	Created: 20190919@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Exchange - Release PRO
*/


update dbo.Products with (rowlock)
set IsTest = 0
where ProductId = 19 -- Exchange

update dbo.Deductions with (rowlock)
set IsTest = 0
where DeductionId in (13, 14) -- Exchange Win Loss Share / Exchange Commission Share