DROP PROCEDURE IF EXISTS Aff_CustomerSel;

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

  DROP TEMPORARY TABLE IF EXISTS tmp_Customer;
  CREATE TEMPORARY TABLE IF NOT EXISTS tmp_Customer(
    CustId INT(11),
    SiteId INT(11),
    UserName VARCHAR(30),
    Userpwd VARCHAR(50),
    CurrencyId TINYINT(4),
    UserLang VARCHAR(4),
    ActStatus TINYINT(4),
    AffId INT,
    UserLevel TINYINT(4),
    LastLoginTime DATETIME,
    RegTime DATETIME,
    FirstDepositTime DATETIME,
    IsTest TINYINT(1),
    IsKyc TINYINT(1),
    IsRisk TINYINT(1),
    Status TINYINT(4)
    );

  INSERT INTO tmp_Customer(CustId, SiteId, AffId, UserName, Userpwd, CurrencyId, UserLang, ActStatus, UserLevel, LastLoginTime, RegTime, FirstDepositTime, IsTest, IsKyc, IsRisk, Status)
    SELECT c.CustId, c.SiteId, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
      FROM Customer c
        INNER JOIN AffCustomer a ON c.CustId = a.CustId
        INNER JOIN CustWallet cw ON c.CustId = cw.CustId
      WHERE cw.FirstDepositTime >= fromDate;

  INSERT INTO tmp_Customer(CustId, SiteId, AffId, UserName, Userpwd, CurrencyId, UserLang, ActStatus, UserLevel, LastLoginTime, RegTime, FirstDepositTime, IsTest, IsKyc, IsRisk, Status)
    SELECT c.CustId, c.SiteId, a.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
	    FROM Customer c
        INNER JOIN AffCustomer a ON c.CustId = a.CustId
		    LEFT JOIN CustWallet cw ON c.CustId = cw.CustId
	    WHERE c.RegTime >= fromDate;

  SELECT DISTINCT c.CustId, s.SiteId, s.SiteName, c.AffId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.UserLevel, c.LastLoginTime, c.RegTime, c.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
    FROM tmp_Customer c
      INNER JOIN ServerInfo s ON s.SiteId = c.SiteId
  ORDER BY s.SiteId, s.SiteName;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE N88_CustomerSel TO 'affiliate_api'@'%';