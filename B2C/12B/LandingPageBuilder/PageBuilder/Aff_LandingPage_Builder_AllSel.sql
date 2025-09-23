/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_LandingPage_Builder_AllSel]
	@IsPreview BIT = 0 -- 0: Main table, 1: Preview table
AS
/*
	Created: 20250913@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select All Landing Page builder and details data
	Revisions:
		- 20250913@Sophia: Initial version [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;

	IF @IsPreview = 1
	BEGIN
		SELECT
			b.PageId,
			b.PageName,
			b.PageCode,
			b.CampaignId,
			b.TargetCountryCode,
			b.MarketId,
			ISNULL(m.TargetLanguageCode, mk.ShortedCode) AS TargetLanguageCode,
			b.DealIds,
			b.StatusId,
			b.Creator,
			b.CreatedDate,
			b.UpdatedBy,
			b.UpdatedDate,
			b.RowVer,
			COALESCE(tp.ExchangeId, e.ExchangeId) AS CurrencyId,
			CAST(1 AS BIT) AS IsPreview
		FROM dbo.LandingPage_Builder_Preview b WITH (NOLOCK)
		INNER JOIN dbo.TargetCountry t WITH (NOLOCK) 
			ON t.CountryCode = b.TargetCountryCode AND t.MarketID = b.MarketId
		INNER JOIN dbo.Market mk WITH (NOLOCK)
			ON mk.MarketId = b.MarketId
		LEFT JOIN dbo.Aff_f_GetTargetLanguageCode() m
			ON mk.ShortedCode = m.ShortedCode
		LEFT JOIN dbo.TPExchange tp WITH (NOLOCK)
			ON tp.CountryCode = b.TargetCountryCode
		LEFT JOIN dbo.Exchange e WITH (NOLOCK)
			ON e.CountryCode = b.TargetCountryCode
		ORDER BY b.PageId DESC;

		SELECT
			d.PageId,
			d.OrderId,
			d.ModuleId,
			d.MediaId,
			d.ExtraInfo,
			mg.FileName,
			mg.MediaName,
			mg.Dimension,
			mg.MediaCode,
			m.ModuleType,
			m.NavigateTo,
			m.IsRequired,
			m.IsUnique,
			mg.RowVer
		FROM dbo.LandingPage_BuilderDetail_Preview d WITH (NOLOCK)
		LEFT JOIN dbo.LandingPage_MediaGallery mg WITH (NOLOCK)
			ON d.MediaId = mg.MediaId
		LEFT JOIN dbo.LandingPage_Module m WITH (NOLOCK)
			ON d.ModuleId = m.ModuleId
		ORDER BY d.PageId DESC, d.OrderId ASC;
	END
	ELSE
	BEGIN
		SELECT
			b.PageId,
			b.PageName,
			b.PageCode,
			b.CampaignId,
			b.TargetCountryCode,
			b.MarketId,
			ISNULL(m.TargetLanguageCode, mk.ShortedCode) AS TargetLanguageCode,
			b.DealIds,
			b.StatusId,
			b.Creator,
			b.CreatedDate,
			b.UpdatedBy,
			b.UpdatedDate,
			b.RowVer,
			COALESCE(tp.ExchangeId, e.ExchangeId) AS CurrencyId,
			CAST(0 AS BIT) AS IsPreview
		FROM dbo.LandingPage_Builder b WITH (NOLOCK)
		INNER JOIN dbo.TargetCountry t WITH (NOLOCK) 
			ON t.CountryCode = b.TargetCountryCode AND t.MarketID = b.MarketId
		INNER JOIN dbo.Market mk WITH (NOLOCK)
			ON mk.MarketId = b.MarketId
		LEFT JOIN dbo.Aff_f_GetTargetLanguageCode() m
			ON mk.ShortedCode = m.ShortedCode
		LEFT JOIN dbo.TPExchange tp WITH (NOLOCK)
			ON tp.CountryCode = b.TargetCountryCode
		LEFT JOIN dbo.Exchange e WITH (NOLOCK)
			ON e.CountryCode = b.TargetCountryCode
		ORDER BY b.PageId DESC;

		SELECT
			d.PageId,
			d.OrderId,
			d.ModuleId,
			d.MediaId,
			d.ExtraInfo,
			mg.FileName,
			mg.MediaName,
			mg.Dimension,
			mg.MediaCode,
			m.ModuleType,
			m.NavigateTo,
			m.IsRequired,
			m.IsUnique,
			mg.RowVer
		FROM dbo.LandingPage_BuilderDetail d WITH (NOLOCK)
		LEFT JOIN dbo.LandingPage_MediaGallery mg WITH (NOLOCK)
			ON d.MediaId = mg.MediaId
		LEFT JOIN dbo.LandingPage_Module m WITH (NOLOCK)
			ON d.ModuleId = m.ModuleId
		ORDER BY d.PageId DESC, d.OrderId ASC;
	END
END;
