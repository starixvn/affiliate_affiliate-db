set ANSI_NULLS ON
set QUOTED_IDENTIFIER ON
go

ALTER Procedure [dbo].[Aff_ExchangeSel]
	@Time smalldatetime=NULL
  
AS

/*
	Created: 
	Task : SELECT exchange rate
	DB: DB052.Affiliate_MYM
	Revisions:
		- 20110223@Peter: Revise
		- 20130219@Joseph: select column Exchange.Code

*/
SET NOCOUNT ON
Select @Time=coalesce(@Time,current_timestamp)
select @Time = dbo.Date_Only(@Time)

if(datediff(d,current_timestamp,@Time)=0)
Begin
	Select c.MultipliedBy,Exchange.* from Exchange (nolock)
	inner join Currency c (nolock) on Exchange.ExchangeID = c.CurrencyID
	 order by Code
End
else
begin

	SELECT ed.*, e.Prefix,c.MultipliedBy
	FROM ExchangeDaily ed with(nolock)
		inner join Currency c (nolock) on ed.ExchangeID = c.CurrencyID	 
		left join Exchange e with (nolock) on e.ExchangeID=ed.ExchangeID
	where [Date]=@Time
	order by ed.Code

end
