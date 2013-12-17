Alter Procedure [Aff_AffiliateSelAffInfo]
AS
--DB052.Affiliate_12BET

Select AffId, Username
From AffInfo with (nolock)
--Where Status = 'Approved'
order by Username

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelAffInfo] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelAffInfo] TO [vnteam]