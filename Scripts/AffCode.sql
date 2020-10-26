use Affiliate_N8B
go

alter table dbo.AffInfo
	add AffCode varchar(20)
go

create table dbo.AffiliateCode
(
	AffCode varchar(20) not null
	,AffId	int null
	,constraint PK_AffiliateCode primary key
	(
		AffCode asc
	) on AffData
) on AffData
go


declare @n int = 10000, @batch int = 5000, @msg varchar(200)
while @n < 99999
begin
	select @msg = 'start insert from ' + convert(varchar(6), @n) + ' to ' + convert(varchar(6), @n + @batch - 1) 
	;with cte_number as
	(
		select @n as n
		union all
		select n + 1
		from cte_number
		where n < @n + @batch - 1
	)
	insert into dbo.AffiliateCode (AffCode)
	select n from cte_number
	option (maxrecursion 0)

	select @n = @n + @batch

	raiserror (@msg, 0, 1) with nowait

	waitfor delay '00:00:00.280'
end
go


declare @tblAffInfo table (id int identity(1,1), AffId int)
insert into @tblAffInfo (AffId)
select affId from dbo.AffInfo with (nolock)
where status not in ('Pending' , 'Disapproved')
order by affId

declare @id int = 1, @AffId int, @AffCode varchar(20)

while exists (select 1 from @tblAffInfo where id = @id)
begin
	select @AffId = AffId from @tblAffInfo where id = @id

	;WITH CTE_AffCode AS
	(
		SELECT TOP 1 * FROM dbo.AffiliateCode WITH (ROWLOCK)
		WHERE AffId IS NULL
		ORDER BY NEWID() -- random
	)
	UPDATE CTE_AffCode
	SET AffId = @AffId

	SELECT @AffCode = AffCode FROM dbo.AffiliateCode WITH (NOLOCK) WHERE AffId = @AffId

	update dbo.AffInfo with (rowlock)
	set AffCode = @AffCode
	where AffId = @AffId

	select @id = @id + 1
end