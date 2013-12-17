ALTER PROC [dbo].[Aff_ExchangeSel]
	@Time smalldatetime
AS
--DB052.Affiliate_12BET
/*
	History:
		Peter@20120116 : Add Buying Rate for Aff Payout
		http://ccs.nexcel.vn/viewtopic.php?f=6&t=8194
*/
SET NOCOUNT ON

declare @Tmp  smalldatetime, @SupportedCurrencies nvarchar(4000)
select @SupportedCurrencies=Svalue
from SystemSettings with (nolock)
where SName='AFF_SupportedCurrencies'

select @Tmp = convert(varchar(10), @Time, 120)

select ex.ExchangeId, Currency, ActualRate2 as ActualRate,BuyingRate2 as BuyingRate
From Exchange ex with (nolock)
	inner join 
	(
		select ExchangeID, max(UpdatedTime) as UpdatedTime
		from Exchange with (nolock) 
		where UpdatedTime <= @Time and Currency in (Select val from dbo.strsplit(@SupportedCurrencies, ';'))
		group by ExchangeID
	) ex1 on ex.ExchangeId = ex1.ExchangeId and ex.UpdatedTime = ex1.UpdatedTime
ORDER BY currency


	
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_ExchangeSel] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ExchangeSel] TO [VNTeam]
