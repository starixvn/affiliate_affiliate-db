/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
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
			  ,u.UserName 		AS Creator
			  ,ad.IsDeleted
			  ,ad.IsSSL
			  ,ad.BlockMarket
		FROM dbo.AffDomain ad WITH (NOLOCK)
			LEFT JOIN Users u WITH (NOLOCK) ON u.CustId = ad.Creator
		WHERE ad.DomainID = @DomainID
		  AND ad.IsDeleted = 0
	END
	ELSE
	BEGIN
		SELECT a.DomainID, a.DomainName, b.UserName AS Creator, a.CreateDate, CONVERT(BIT, ISNULL(a.IsSSL, 0)) AS IsSSL, ISNULL(oam.BlockMarket, '') AS BlockMarket
		FROM dbo.AffDomain a WITH (NOLOCK)
			LEFT JOIN dbo.Users b WITH (NOLOCK) ON a.Creator = b.CustId
			OUTER APPLY(
				SELECT STRING_AGG(m.MarketName, ', ') AS BlockMarket
				FROM dbo.UserMarket um WITH (NOLOCK)
					INNER JOIN dbo.Market m WITH (NOLOCK) ON m.MarketId = um.MarketId
					INNER JOIN STRING_SPLIT(a.BlockMarket, ',') s ON s.value = m.MarketId
				WHERE um.CustId = @UserId
			) As oam
		WHERE a.IsDeleted = 0
		ORDER BY a.DomainName
	END
END
GO