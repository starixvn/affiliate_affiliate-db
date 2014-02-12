ALTER PROCEDURE [dbo].[Aff_PlayerPayoutInfoSel]
	@AffId int,
	@PlayerUsername varchar(30) OUTPUT,
	@SystemName varchar(30) OUTPUT,
	@DummyBalAcc varchar(30) OUTPUT,
	@AffCurrency varchar(6) OUTPUT = 'MYR'
AS
/*
	Task : Get all information of existing member
	DB : DB054.Affiliate_Zzun
		- Johnny@2013Mar25: Return test account (UUS balance account)
*/


select @PlayerUsername = Player_Username from AffDetail nolock where AffId = @AffId

select @SystemName = SValue From SystemSettings nolock where SName = 'SystemName' and Type = 'Meta'

Declare @Player_Currency varchar(50)

Select @Player_Currency = dbo.[Aff_PlayerCurrencyByAffId] (@AffId)

Select @AffCurrency = e.code from affinfo a 
inner join exchange e on e.ExchangeID = a.Currency 
where a.affid = @AffId
--For Real Currency
Select @DummyBalAcc = SValue
From SystemSettings nolock
where SName like 'AFF_BalPlayer' + @Player_Currency
	and Type = 'Meta'




GO
GRANT EXECUTE ON [dbo].[Aff_PlayerPayoutInfoSel] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_PlayerPayoutInfoSel] TO [vnTeam]
GO