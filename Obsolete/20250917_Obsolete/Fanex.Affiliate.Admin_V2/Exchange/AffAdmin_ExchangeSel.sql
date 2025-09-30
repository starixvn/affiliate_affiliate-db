-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_ExchangeSel]	
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
	Select cc.MultipliedBy,e.* from Exchange (nolock) e
	inner join Currency cc (nolock) on e.ExchangeID = cc.CurrencyID
	order by e.Code
End
else
begin

	SELECT ed.*,cc.MultipliedBy
	FROM ExchangeDaily ed with(nolock)	
	inner join Currency cc (nolock) on ed.ExchangeID = cc.CurrencyID			
	where [Date]=@Time
	order by ed.Code
end



GO
GRANT EXECUTE ON [dbo].[AffAdmin_ExchangeSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ExchangeSel] TO [vnteam]