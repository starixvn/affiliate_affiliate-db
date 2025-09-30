CREATE Procedure [dbo].[AffAdmin_PlayerPayoutInfoSel]
	@AffId int,
	@RefId bigint
AS
/*
	Task : Get all information of existing member
	DB : DB054.Affiliate_MYM
		- Johnny@2013Mar25: Return test account (UUS balance account)
*/

	Declare @PlayerUsername varchar(30)
	Declare @SystemName varchar(30)
	Declare @DummyBalAcc varchar(30)
	Declare @AffCurrency varchar(6)

SELECT
	@PlayerUsername = Player_Username
FROM AffDetail nolock
WHERE AffId = @AffId

SELECT @SystemName = SValue
FROM SystemSettings nolock
WHERE SName = 'SystemName' AND Type = 'Meta'

Declare @Player_Currency varchar(50)
SELECT @Player_Currency = CurrencyCode
FROM AffPayout WITH (NOLOCK) INNER JOIN Currency WITH (NOLOCK)
ON AffPayout.MemberCurrency = Currency.CurrencyID
where RefID = @RefId and AffID = @AffId

SELECT @AffCurrency = e.code
FROM affinfo a
INNER JOIN exchange e
	ON e.ExchangeID = a.Currency
WHERE a.affid = @AffId

--For Real Currency
SELECT @DummyBalAcc = SValue
FROM SystemSettings nolock
WHERE SName LIKE 'AFF_BalPlayer' + @Player_Currency
AND Type = 'Meta'

Select @PlayerUsername 'PlayerUsername',
	@SystemName 'SystemName',
	@DummyBalAcc 'DummyBalAcc',
	@AffCurrency 'AffCurrency'

GO
GRANT EXECUTE ON [dbo].[AffAdmin_PlayerPayoutInfoSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PlayerPayoutInfoSel] TO [vnteam]