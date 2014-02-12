ALTER PROCEDURE [dbo].[Aff_ResourcesTranslationSel]	
	@ResourceType varchar(50) =NULL,
	@LanguageCode varchar(8)=NULL,
	@Key varchar(50)=NULL,
	@Value nvarchar(256)=NULL,
	@Option int = 0,
	@TotalPages int = 0 OUTPUT,
	@NRows int=0 OUTPUT
AS

SET NOCOUNT ON

SELECT @Key='%' + isnull(rtrim(ltrim(@Key)),'') + '%'
SELECT @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'
DECLARE @Types TABLE
(
  SName varchar(50)
)
if @ResourceType is null 
	insert into @Types select SName from systemsettings where type ='ResourceRefID'

IF(@Option=1)
	BEGIN		
		declare @langCount int
		set @langCount = (select count(*) From Language (NOLOCK))
		
		select R.RefID,R.ResourceKey,R.LanguageCode,R.ResourceValue, L.LanguageName as SValue
		from RefResources R (NOLOCK)
		inner join Language L ON L.LanguageID = R.LanguageCode
		Inner join 
		(
					SELECT DISTINCT R.RefID,R.ResourceKey
					from RefResources R (NOLOCK)
					where R.LanguageCode In (select LanguageID From Language (NOLOCK))					
					AND RefID != 'AffiliateContent'	
					AND ((@ResourceType is null and RefID in (Select SName from @Types)) or RefID = @ResourceType)
					AND R.ResourceKey LIKE @Key
					AND (R.ResourceValue IS NULL OR R.ResourceValue  LIKE @Value )
					group by R.RefID, R.ResourceKey
					having count(R.LanguageCode) < @langCount
		) T on R.RefID = T.RefID and R.ResourceKey =T.ResourceKey			
	
		order by R.RefID, R.ResourceKey,R.LanguageCode	
	END
ELSE
	BEGIN

		SELECT DISTINCT R1.ResourceID,R1.RefID,R1.LanguageCode, R1.ResourceKey,R1.ResourceValue,S.LanguageName as [SValue]
		FROM RefResources  AS R1 WITH (NOLOCK),
				(
					SELECT DISTINCT R1.[ResourceKey]
								FROM RefResources  AS R1 WITH (NOLOCK), 
									RefResources AS R2 WITH (NOLOCK)
								WHERE R1.[LanguageCode]='en-US'
								AND R2.[LanguageCode] <> 'en-US'
								AND R1.RefID != 'AffiliateContent'	
								AND R2.RefID != 'AffiliateContent'	
								AND ((@ResourceType is null and R1.RefID in (Select SName from @Types)) or R1.RefID = @ResourceType)
								AND R1.[ResourceKey] = R2.[ResourceKey]
								--AND R1.[ResourceValue]=R2.[ResourceValue]
				)R2 ,Language S(NOLOCK)
		WHERE	((@ResourceType is null and R1.RefID in (Select SName from @Types)) or R1.RefID = @ResourceType)
				AND R1.RefID != 'AffiliateContent'	
				AND R1.LanguageCode = coalesce(@LanguageCode,R1.LanguageCode) 
				AND R1.ResourceKey LIKE @Key
				AND (R1.ResourceValue IS NULL OR R1.ResourceValue  LIKE @Value )
				AND R1.[ResourceKey] = R2.[ResourceKey]				
				AND S.LanguageID = R1.[LanguageCode]
		ORDER BY R1.RefID,R1.ResourceKey,R1.LanguageCode

	END
	 
	 
 GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTranslationSel] TO [bodbDownlineNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationSel] TO [VNTeam]