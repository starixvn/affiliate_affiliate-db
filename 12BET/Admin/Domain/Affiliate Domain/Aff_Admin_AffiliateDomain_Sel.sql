/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliateDomain_Sel]
	@DomainID	INT = 0
	,@UserId	INT = 0
AS

/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - Affiliate Domain - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20221101@Eddie: Support Block Market [RedmineID: #179537]
		- 20231031@Eddie: Change BlockMarket to BlockTargetCountry [RedmineID: #181590]
		- 20240821@Eddie: Change metadata "bodbAdminNet" [RedmineID: #209409]
*/

BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)
	
	IF(@DomainID <> 0)
	BEGIN
		SELECT ad.DomainID
			  ,ad.DomainName
			  ,ad.CreateDate
			  ,ad.ModifyDate
			  ,u.UserName AS Creator
			  ,ad.IsDeleted
			  ,ad.IsSSL
			  ,ad.BlockTargetCountry
		FROM dbo.AffDomain ad WITH (NOLOCK)
			LEFT JOIN Users u WITH (NOLOCK) ON u.CustId = ad.Creator
		WHERE ad.DomainID = @DomainID
		  AND ad.IsDeleted = 0
	END
	ELSE
	BEGIN
		SELECT a.DomainID
			  ,a.DomainName
			  ,b.UserName AS Creator
			  ,a.CreateDate
			  ,CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
			  ,ISNULL(oam.BlockTargetCountry, '') AS BlockTargetCountry
		FROM dbo.AffDomain a WITH (NOLOCK)
			LEFT JOIN dbo.Users b WITH (NOLOCK) ON a.Creator = b.CustId
			OUTER APPLY(
				SELECT STRING_AGG(t.CountryName, ', ') AS BlockTargetCountry
				FROM(
					SELECT tc.CountryName
					FROM dbo.UserMarket um WITH (NOLOCK)
						INNER JOIN dbo.TargetCountry tc WITH (NOLOCK) ON tc.MarketID = um.MarketId
						INNER JOIN STRING_SPLIT(a.BlockTargetCountry, ',') s ON s.value = tc.CountryCode
					WHERE um.CustId = @UserId
					GROUP BY tc.CountryName
				) AS t
			) As oam
		WHERE a.IsDeleted = 0
		ORDER BY a.DomainName
	END
END
GO