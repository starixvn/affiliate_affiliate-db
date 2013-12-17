ALTER PROCEDURE [dbo].[AffAdmin_PaymentRequestSelList]
    @Username			NVARCHAR(30) = NULL,
	@AffType			varchar(20),
    @Status				VARCHAR(100) = NULL,   
	@PreferredLanguage	varchar(100) = NULL,
    @Currency			varchar (100),
	@DateOption			tinyint = 0,
    @Fromdate			DATETIME  = NULL,
    @Todate				DATETIME  = NULL,
	@BaseCurrency		varchar(5) = '',
	@IsITAdmin			bit = 0,
	@ExcludeTest		bit = 0
AS
/*
 Task : Get All Affiliate for a specific page
DB: 
Original: [Aff_BettransSelRequestPaymentList]
Revisions:   
	-
Param's Explanation:
• @Username: Affiliate username need to search
• @AffType: List Affiliate Type
• @Status : pending,Approved,disapproved
• @PreferredLanguage: Preferred language
• @Currencies: List currency Id
• @DateOption : 0 for all, 1 for requested date, 2 for completed date
• @Fromdate :  default value=null :search all
• @Todate :  default value=null :search all
• @BaseCurrency: Convert affiliate money to system money or not
• @SortBy: Affiliate name or amount
• @ExcludedTestAcc: Exclude test acount or not
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search
• @NRows OUTPUT,--total of rows
 */
 SET NOCOUNT ON
DECLARE @RowStart int, @TransType int, @ToCurrency int, @ToCurrencyCode varchar(10), @SystemCurrency int
select @TransType = 202 --payment request
select @Username= '%' + Coalesce(@Username, '') + '%'
		, @BaseCurrency = ISNULL(@BaseCurrency, '')
		, @ToDate = [dbo].[Aff_GetEndDate] (@ToDate)

--Convert aff currency to system currency
Select @ToCurrency = ExchangeId, @ToCurrencyCode = Code
from Exchange nolock
where Code in (SELECT SValue from SystemSettings nolock WHERE SName = 'SystemCurrency' AND Type = 'Meta')

-- AffType
DECLARE @AffTypeTable TABLE (AffType INT)
INSERT INTO @AffTypeTable
SELECT CAST(val AS INT) 
FROM [dbo].[strSplit] ( @AffType, ',' )

DECLARE @PaymentStatusTable TABLE (PaymentStatus varchar(20))
INSERT INTO @PaymentStatusTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @Status, ',' )

DECLARE @PreferredLanguageTable TABLE (PreferredLanguage varchar(20))
INSERT INTO @PreferredLanguageTable
SELECT CAST(val AS varchar(20)) 
FROM [dbo].[strSplit] ( @PreferredLanguage, ',' )

DECLARE @CurrenciesTable TABLE (Currency varchar(5))
INSERT INTO @CurrenciesTable
SELECT CAST(val AS varchar(5)) 
FROM [dbo].[strSplit] ( @Currency, ',' )

----------Retrieve data--------------
Select a.TransID,
		b.UserName,
		c.PreferredLanguage,
		d.Name as AffType,
		(case when a.Status = 'Pending' THEN 'Processing' ELSE a.Status END) as Status,
		b.UserName,
		a.TransDate,
		a.CompletedDate,
		ABS(
		CASE @BaseCurrency 
			WHEN '' THEN a.Amount 
			else cast(a.Amount * dbo.Aff_GetExchangeRate(b.Currency, @ToCurrency, null) as Money)
		end) as Amt,
		ABS(cast(a.Amount * dbo.Aff_GetExchangeRate(b.Currency, @ToCurrency, null) as Money)) as ConvertedAmt,
		dbo.Aff_GetExchangeRate(b.Currency, @SystemCurrency, null) as ExchangeRate, 
		ex.Code as Currency,
		case when a.Status in ('Pending','Cancelled') and a.TransType=202 then b.UserName  
				else admin.username  
		end  as Creator  
from AffTrans a with (NOLOCK)
	INNER JOIN AffInfo b WITH (nolock) ON a.AffId = b.AffId
	INNER JOIN AffDetail c WITH (nolock) ON b.AffId = c.AffId
	INNER JOIN Exchange ex WITH (nolock) ON b.Currency = ex.ExchangeID
	INNER JOIN AffType d  WITH (nolock) ON b.AffType = d.TypeID
	LEFT Join AdminUser admin on a.creator = admin.CustId  
where TransType = @TransType
	and b.Username like @Username
	AND b.AffType in (SELECT AffType from @AffTypeTable)
	AND a.[Status] in (SELECT PaymentStatus from @PaymentStatusTable)
	and b.Currency in (SELECT Currency from @CurrenciesTable)
	and c.PreferredLanguage in (SELECT PreferredLanguage from @PreferredLanguageTable)
	and (@DateOption = 0 OR (@DateOption = 1 AND a.TransDate BETWEEN @FromDate AND @ToDate)
					 OR (@DateOption = 2 AND a.CompletedDate BETWEEN @FromDate AND @ToDate))
	
	and (
			(@ExcludeTest = 1 AND b.TestLevel = 0) 
			OR (@ExcludeTest = 0 AND @IsITAdmin = 1) 
			OR (@ExcludeTest = 0 AND @IsITAdmin = 0 AND b.TestLevel IN (0,1))
		)
order by CASE a.status  
		   WHEN 'Pending' THEN 1  
		   WHEN 'Approved' THEN 2  
		   WHEN 'Rejected' THEN 3  
		   ELSE 4  
		END, transid desc

GO
GRANT EXECUTE ON [dbo].[AffAdmin_PaymentRequestSelList] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_PaymentRequestSelList] TO [vnteam]