CREATE PROCEDURE [dbo].[AffAdmin_BannerSel]
	@Category smallint=NULL,
	@Language varchar(8)=NULL,
	@ImageType smallint=NULL,
	@Size smallint=NULL,
	@Currency smallint=NULL,
	@Type tinyint=0,
	@PageSize int=50,
	@PageIndex int=1,
	@TotalPages int=0 OUTPUT,
	@NRows int=0 OUTPUT
AS

/*Created: 20090328@DungTong
Task : Search all Aff Banner Paging
DB:  DB052.Affiliate_12BET

Revisions:    
	- 20130207@Johnny: Filter by Type(1: normal banner; 2: media banners)
			  
Param's Explanation:
• @Category : Search by Category value=null :search all
• @Language : Search by Language value=null :search all
• @ImageType : Search by ImageType value=null :search all
• @Size : Search by Size value=null :search all
• @Currency : Search by Currency value=null :search all
• @Type: type of banners(1: normal banner; 2: media banners)
• @PageSize : Number of rows should be returned per each page
• @PageIndex : Current page 
• @TotalPages OUTPUT : total of pages for this search

• @NRows OUTPUT,--total of rows

*/

SET NOCOUNT ON
 declare @SubCategory table(id int)
 
if isnull(@Category,0)<>0
begin
INSERT INTO @SubCategory (id)
	SELECT
		typeid
	FROM BannerTypes
	WHERE parentid = @Category UNION SELECT
		@Category
end


--count nrows
SELECT
	@NRows = COUNT(1)
FROM Banners WITH (NOLOCK)
WHERE (@Category IS NULL OR Category IN (SELECT
	id
FROM @SubCategory)
)
AND (@Language IS NULL OR Language = @Language)
AND (@ImageType IS NULL OR ImageType = @ImageType)
AND (@Size IS NULL OR size = @Size)
AND (@Currency IS NULL OR Currency = @Currency)
AND (@Type IS NULL OR Type = @Type)
	  
DECLARE @RowStart int, @RowEnd int

SELECT
	@TotalPages = @NRows / @PageSize + CASE
		WHEN @NRows % @PageSize > 0 THEN 1 ELSE 0
	END,
	@PageIndex = @PageIndex - 1,
	@RowStart = @PageSize * @PageIndex + 1,
	@RowEnd = @RowStart + @PageSize - 1

SELECT
	BannerID,
	[Content],
	Category,
	[Language],
	LanguageCode,
	ImageType,
	[Size],
	Lastupdate,
	Currency,
	Type,
	Version,
	TotalRequest,
	LastRequest
FROM (SELECT TOP (@RowEnd)
	ROW_NUMBER() OVER (ORDER BY bannerid DESC) AS TheCount,
	BannerID,
	[Content],
	btc.Value AS Category,
	l.LanguageID AS LanguageCode,
	l.LanguageName AS [Language],
	bti.Value AS ImageType,
	bts.Value AS [Size],
	Lastupdate,
	c.CurrencyName AS Currency,
	b.Type,
	Version,
	TotalRequest,
	LastRequest
FROM Banners b WITH (NOLOCK)
LEFT JOIN BannerTypes bts
	ON bts.TypeID = b.Size
LEFT JOIN BannerTypes bti
	ON bti.TypeID = b.ImageType
INNER JOIN BannerTypes btc
	ON btc.TypeID = b.Category
INNER JOIN Language l
	ON l.LanguageID = b.Language
INNER JOIN Currency c
	ON c.CurrencyID = b.Currency

WHERE (@Category IS NULL OR b.Category IN (SELECT
	id
FROM @SubCategory)
)
AND (@Language IS NULL OR b.Language = @Language)
AND (@ImageType IS NULL OR b.ImageType = @ImageType)
AND (@Size IS NULL OR b.size = @Size)
AND (@Currency IS NULL OR b.Currency = @Currency)
AND (@Type IS NULL OR b.Type = @Type)) x
WHERE x.TheCount BETWEEN @RowStart AND @RowEnd

GO
GRANT EXECUTE ON [dbo].[AffAdmin_BannerSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_BannerSel] TO [vnteam]