/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210121@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: Integrate BTi Product - Update Setting's Affective Date
*/
use Affiliate_12BET
go

update dbo.DeductionSettingHistory with (rowlock)
set MonthDate = '2021-01-31'
where ProductId = 25
	and MonthDate = '2020-07-31'