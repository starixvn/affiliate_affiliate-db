/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_12BETDomain_Sel]
	@DomainID	INT = 0
	,@UserId	INT = 0
AS
/*  
	Created: 20191010@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Domain - 12BET Domain - Select

	Revisions:
		- 20191010@Percy: Initialize SP [RedmineID: #118992]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
		- 20221108@Eddie: Support Block Market [RedmineID: #179537]
		- 20231101@Eddie: Change BlockMarket to BlockTargetCountry [RedmineID: #181590]
*/
BEGIN
	SET NOCOUNT ON
	
	SET @UserId = ISNULL(@UserId, 0)
	
	IF(@DomainID <> 0)
	BEGIN
		SELECT bd.DomainID
			  ,bd.DomainName
			  ,bd.CreateDate
			  ,bd.ModifyDate
			  ,u.UserName 		AS Creator
			  ,bd.DeviceType
			  ,bd.IsDeleted
			  ,bd.W3Prefix
			  ,bd.IsSSL
			  ,bd.BlockTargetCountry
		FROM dbo.[12BetDomain] bd WITH (NOLOCK)
			LEFT JOIN Users u WITH (NOLOCK) ON u.CustId = bd.Creator
		WHERE bd.DomainID = @DomainID
		  AND bd.IsDeleted = 0
	END
	ELSE
	BEGIN
		SELECT a.DomainID
			  ,a.DomainName
			  ,b.UserName AS Creator
			  ,a.CreateDate
			  ,CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL
			  ,ISNULL(oam.BlockTargetCountry, '') AS BlockTargetCountry
		FROM dbo.[12BetDomain] a WITH (NOLOCK)
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