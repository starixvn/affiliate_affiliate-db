/*<info serverAlias="DBEXT-bodb02" executers="wsv_nap,wsv_nap" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_API_ExchangeDailyOanda_Sel]
	@ExchangeDate	SMALLDATETIME
	,@ExchangeIds	VARCHAR(MAX)
AS
/*
	Created: 20221031@Malcolm
	DB: DBEXT-bodb02
	Task: Get ExchangeDailyOanda information

	Revisions:
		- 20221031@Malcolm: Initialize SP [RedmineID: #179654]
*/

BEGIN
	SET NOCOUNT ON

	
	DECLARE @TmpExchange TABLE(
		ExchangeId	INT ,Code VARCHAR(12) ,MYR FLOAT, USD FLOAT, EUR FLOAT, CNY FLOAT, IDR FLOAT, AUD FLOAT, CHF FLOAT
		,GBP FLOAT, SGD FLOAT, THB FLOAT, VND FLOAT, KRW FLOAT, JPY FLOAT, HKD FLOAT, TWD FLOAT, PHP FLOAT, BDT FLOAT, INR FLOAT
	)

	INSERT INTO @TmpExchange (ExchangeId, Code, MYR, USD, EUR, CNY, IDR, AUD, CHF, GBP, SGD, THB, VND, KRW, JPY, HKD, TWD, PHP, BDT, INR)
	SELECT ExchangeId, Code, MYR, USD, EUR, CNY, IDR, AUD, CHF, GBP, SGD, THB, VND, KRW, JPY, HKD, TWD, PHP, BDT, INR
	FROM dbo.ExchangeDailyOanda e WITH(NOLOCK)
	WHERE e.ExchangeDate = @ExchangeDate AND e.ExchangeId IN (SELECT CONVERT(INT, Value) FROM STRING_SPLIT(@ExchangeIds, ','))

	SELECT t.ExchangeId, t.Code, n.Currency, n.Rate
	FROM @TmpExchange t
	CROSS APPLY 
	(
		SELECT 'MYR', MYR
		UNION ALL
		SELECT 'USD', USD
		UNION ALL
		SELECT 'EUR', EUR
		UNION ALL
		SELECT 'CNY', CNY
		UNION ALL
		SELECT 'IDR', IDR
		UNION ALL
		SELECT 'AUD', AUD
		UNION ALL
		SELECT 'CHF', CHF
		UNION ALL
		SELECT 'GBP', GBP
		UNION ALL
		SELECT 'SGD', SGD
		UNION ALL
		SELECT 'THB', THB
		UNION ALL
		SELECT 'VND', VND
		UNION ALL
		SELECT 'KRW', KRW
		UNION ALL
		SELECT 'JPY', JPY
		UNION ALL
		SELECT 'HKD', HKD
		UNION ALL
		SELECT 'TWD', TWD
		UNION ALL
		SELECT 'PHP', PHP
		UNION ALL
		SELECT 'BDT', BDT
		UNION ALL
		SELECT 'INR', INR
	) AS n(Currency, Rate)
	ORDER BY t.ExchangeId ASC, t.Code ASC, n.Currency ASC
END
GO