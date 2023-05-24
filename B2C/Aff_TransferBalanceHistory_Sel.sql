/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_TransferBalanceHistory_Sel]
	@AffId					INT = 0
	,@AffName				VARCHAR(50) = ''
	,@PlayerName			VARCHAR(50) = ''
	,@TransId				BIGINT = 0
	,@FromDate				DATETIME
	,@ToDate				DATETIME
	,@BaseCurrency			INT = 0
	,@PageIndex				INT = 1
	,@PageSize				INT = 50
	,@IsExportExcel			BIT = 0
	,@NRows					INT = 0 OUTPUT
	,@TotalAffPlayerAmount	MONEY = 0 OUTPUT
	,@TotalBasedAmount		MONEY = 0 OUTPUT
AS

/*
	Created: 20211005@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Transfer Balance For Player

	Revisions:
		- 20211005@Percy: Initialize SP [RedmineID: #153227]
		- 20230522@Sally: Support Currency BDT, USD 72 [RedmineID: #188429]
*/

BEGIN
	SET NOCOUNT ON

	--Get base currency mapping
	DECLARE @BaseExchangeId INT = @BaseCurrency
	SELECT @BaseExchangeId = t.ExchangeId
	FROM dbo.TpExchange t WITH (NOLOCK)
	WHERE t.TpExchangeId = @BaseCurrency

	SELECT @AffId = ISNULL(@AffId, 0), @AffName = ISNULL(@AffName, ''), @PlayerName = ISNULL(@PlayerName, '')
		,@TransId = ISNULL(@TransId, 0)
		,@FromDate = CONVERT(DATE, @FromDate), @ToDate = CONVERT(DATE, @ToDate) -- get date only
		,@IsExportExcel = ISNULL(@IsExportExcel, 0)

	IF @AffId <> 0
		SET @AffName = ''

	CREATE TABLE #tmpData (
		TransId BIGINT, TransTime DATETIME, Status VARCHAR(20), AffName VARCHAR(50), AffPlayerName VARCHAR(50), PlayerName VARCHAR(50)
		,Currency INT, CurrencyCode VARCHAR(3), Amount MONEY
		,AffPlayerCurrencyCode VARCHAR(3), AffPlayerAmount MONEY
		,BasedAmount MONEY
	)
	INSERT INTO #tmpData (
		TransId, TransTime, Status, AffName, AffPlayerName, PlayerName
		,Currency, CurrencyCode, Amount
		,AffPlayerCurrencyCode, AffPlayerAmount
	)
	SELECT
		TransId, TransTime, Status, AffUserName, Player_UserName, UserName
		,Currency, CurrencyCode, Amount
		,Player_CurrencyCode, Amount * ExRate
	FROM dbo.TransferBalanceHistory WITH (NOLOCK)
	WHERE TransDate BETWEEN @FromDate AND @ToDate
		AND (@TransId = 0 OR TransId = @TransId)
		AND (@AffId = 0 OR AffId = @AffId)
		AND (@AffName = '' OR AffUserName LIKE '%' + @AffName + '%')
		AND (@PlayerName = '' OR UserName LIKE '%' + @PlayerName + '%')
	
	UPDATE t
	SET t.BasedAmount = t.Amount * e.Rate
	FROM #tmpData t
		LEFT JOIN dbo.TpExchange tp WITH (NOLOCK) ON t.Currency = tp.TpExchangeId
		CROSS APPLY dbo.Aff_f_ExchangeRate_Sel(t.TransTime, ISNULL(tp.ExchangeId, t.Currency), @BaseExchangeId) e

	SELECT @NRows = COUNT(1), @TotalBasedAmount = SUM(BasedAmount), @TotalAffPlayerAmount = SUM(AffPlayerAmount) FROM #tmpData
	
	-- Paging
	DECLARE @RowStart INT, @RowEnd INT

	IF @IsExportExcel = 1
		SELECT @RowStart = 1, @RowEnd = @NRows
	ELSE
		SELECT @RowStart = @PageSize * (@PageIndex - 1) + 1, @RowEnd = @RowStart + @PageSize - 1

	SELECT
		TransId, TransTime, Status, AffName, AffPlayerName, PlayerName
		,CurrencyCode AS Currency, Amount, AffPlayerCurrencyCode AS AffPlayerCurrency, AffPlayerAmount, BasedAmount
	FROM (
		SELECT
			TransId, TransTime, Status, AffName, AffPlayerName, PlayerName
			,CurrencyCode, Amount, AffPlayerCurrencyCode, AffPlayerAmount, BasedAmount
			,ROW_NUMBER() OVER(ORDER BY TransTime DESC) AS RN
		FROM #tmpData
	) t
	WHERE RN BETWEEN @RowStart AND @RowEnd

	DROP TABLE #tmpData
END
GO