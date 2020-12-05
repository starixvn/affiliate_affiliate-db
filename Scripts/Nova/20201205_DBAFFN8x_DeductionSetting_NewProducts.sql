/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G"></info>*/
/*
	Created: 20201205@Percy
	DB:
		DBAFFN88-Affiliate_N88
		DBAFFN8B-Affiliate_N8B
		DBAFFN8G-Affiliate_N8G
	Task: Insert setting new products

	use Affiliate_N88
	go
	use Affiliate_N8B
	go
	use Affiliate_N8G
	go
*/

declare @product table (ProductId int)
insert into @product (ProductId)
select ProductId
from dbo.Products p with (nolock)
where not exists (select 1 from dbo.DeductionSetting s where p.ProductId = s.ProductId)

if exists (select 1 from @product)
begin
	insert into dbo.DeductionSetting (GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
	select GroupId,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
	from (
		select GroupId,DeductionId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		from dbo.DeductionSetting with (nolock)
		where ProductId = 1 and DeductionId = 10
	) g
	cross join @product p

	insert into dbo.DeductionSettingHistory (GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent)
	select GroupId,MonthDate,DeductionId,ProductId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
	from (
		select GroupId,MonthDate,DeductionId,GroupProductId,DeductedPercentage,DeductedAmount,IsDeductedPercent
		from dbo.DeductionSettingHistory with (nolock)
		where ProductId = 1 and DeductionId = 10 and MonthDate in ('2020-10-31', '2020-11-30')
	) g
	cross join @product p
end