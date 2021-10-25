/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/

/*
	Created: 20211020@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/

use Affiliate_12BET
go

declare @i int, @msg varchar(100), @NRows int, @NoOfBatch int
select @NRows = count(1) from dbo.APIProduct_ImportQueue with (nolock)
where ProductId = 13 and CheckInTime < '2021-10-01'

select @NoOfBatch = @NRows/5000 + 1, @i = 1

while 1 = 1
begin
	set @msg = 'start batch: ' + convert(varchar(10), @i) + ' / ' + convert(varchar(10), @NoOfBatch)
	raiserror (@msg, 1, 0) with nowait
	
	delete top (5000) dbo.APIProduct_ImportQueue with (rowlock)
	where ProductId = 13 and CheckInTime < '2021-10-01'

	if @@rowcount < 5000
		break

	waitfor delay '00:00:00.280'

	select @i = @i + 1
end