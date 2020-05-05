DROP PROCEDURE IF EXISTS `Aff_CustomerSel`;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `Aff_CustomerSel`(
  IN fromDate DATETIME
  /*
    Created: 20200220@Percy
    DB: Slave DB/Siebog
    Task: Get players which registered time or deposited time from fromDate
    
    Revisions:
    - 20200220@Percy: Initialize SP

  */
)
BEGIN
    SELECT c.CustId, c.SiteId, s.SiteName, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
      FROM `Customer` c
        INNER JOIN `Affiliate_VN` a ON a.CustId = c.CustId AND a.SiteId = c.SiteId
        INNER JOIN `CustWallet` cw ON cw.CustId = c.CustId
		INNER JOIN `ServerInfo` s ON c.SiteId = s.SiteId
      WHERE cw.FirstDepositTime >= fromDate
    
    UNION
    SELECT c.CustId, c.SiteId, s.SiteName, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
	  FROM `Customer` c
        INNER JOIN `Affiliate_VN` a ON a.CustId = c.CustId AND a.SiteId = c.SiteId
		LEFT JOIN `CustWallet` cw ON cw.CustId = c.CustId
		INNER JOIN `ServerInfo` s ON c.SiteId = s.SiteId
	  WHERE c.RegTime >= fromDate
    
    ORDER BY SiteId, SiteName;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE `Aff_CustomerSel` TO 'affiliate_api'@'%';