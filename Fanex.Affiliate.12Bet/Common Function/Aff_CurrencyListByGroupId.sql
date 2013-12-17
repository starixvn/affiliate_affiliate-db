ALTER Function [dbo].[Aff_CurrencyListByGroupId]
(
	@GroupID int
)
returns @res table (Currency varchar(10))
AS
Begin
	Declare @CurrencyList varchar(200)

	Select @CurrencyList = CurrencyList
	From CurrencyGroup nolock
	where GroupId = @GroupId

	insert into @res

	select ExchangeId
	from [dbo].[strSplit](@CurrencyList, ',') as tmp
		inner join exchange_current e on tmp.Val = e.Currency
					
	return 
End
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CurrencyListByGroupId] TO [vnteam]
