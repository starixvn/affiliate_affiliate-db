Alter Procedure [DEP_AffiliateSelTotalRegistered]
	@Fromdate datetime,
	@Todate datetime,
	@IsGetAll bit,
	@ListAffId varchar(4000)
AS

-- DB: DEPOSIT.Deposit_DB
Declare @splitter char( 1), @string nvarchar(4000)
select @splitter = ';', @string = @ListAffId

Declare @res table(AffId int)

if substring ( @string, len ( @string), 1)<>@splitter
	set @string= @string+@splitter
declare @start int, @word nvarchar(4000), @charindex int, @i int, @AffId int
set @i=1
set @start=1
set @charindex= charindex( @splitter, @string, @start)
while (@charindex <> 0)begin
	set @word= substring( @string, @start, @charindex - @start)
	set @start= @charindex +1
	set @charindex= charindex( @splitter, @string, @start)
	
	select @AffId = Cast(@word as int)
	
	insert into @res  values (@AffId)
	set @i=@i+1
end


if @IsGetAll = 1
Begin
	SELECT r.AffID,
		COUNT(CustId) as TotalRegistered
	FROM @res r
		left join Deposit_Customer d WITH(NOLOCK) on r.AffId = d.AffiliateId
	Group by r.AffID
End
Else
Begin
	Select @ToDate = dateadd(s, -1, dateadd(d, datediff(d, 0, @ToDate) + 1, 0))
	
	SELECT r.AffID,
		COUNT(CustId) as TotalRegistered
	FROM @res r
		left join 
		(
			select CustId, AffiliateId
			From Deposit_Customer WITH(NOLOCK) 
			where creatdate between @FromDate and @ToDate
		) d
		on r.AffId = d.AffiliateId
	Group by r.AffID
End

GO
GRANT EXECUTE ON [dbo].[DEP_AffiliateSelTotalRegistered] TO [bodbAffiliateNet]
GO
GRANT VIEW DEFINITION ON [dbo].[DEP_AffiliateSelTotalRegistered] TO [VNTeam]
GO