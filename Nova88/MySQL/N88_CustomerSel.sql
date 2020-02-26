DROP PROCEDURE IF EXISTS N88_CustomerSel;

DELIMITER //

CREATE DEFINER=`aff_user`@`%` PROCEDURE `N88_CustomerSel`(
		IN fromDate DATETIME
    	/*
			Creator: Hubert@20200220
            DB: 10.18.200.109/Siebog
			Task: Select customers have registation time from fromDate to now
			Params:
					- regTime: registation time
			Revisions:
					- 20200220@Hubert: Create        
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
    AgentId INT(11),
    AllAgentId JSON,
    UserLevel TINYINT(4),
    LastLoginTime DATETIME,
    RegTime DATETIME,
    FirstDepositTime DATETIME,
    IsTest TINYINT(1),
    IsKyc TINYINT(1),
    IsRisk TINYINT(1),
    Status TINYINT(4)
    );

  INSERT INTO tmp_Customer(CustId, SiteId, UserName, Userpwd, CurrencyId, UserLang, ActStatus, AgentId, AllAgentId, UserLevel, LastLoginTime, RegTime, FirstDepositTime, IsTest, IsKyc, IsRisk, Status)
    SELECT c.CustId, c.SiteId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.AgentId, c.AllAgentId, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
      FROM Customer c
        INNER JOIN CustWallet cw ON c.CustId = cw.CustId
      WHERE c.AgentId > 0
		AND cw.FirstDepositTime >= fromDate;

  INSERT INTO tmp_Customer(CustId, SiteId, UserName, Userpwd, CurrencyId, UserLang, ActStatus, AgentId, AllAgentId, UserLevel, LastLoginTime, RegTime, FirstDepositTime, IsTest, IsKyc, IsRisk, Status)
    SELECT c.CustId, c.SiteId, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.AgentId, c.AllAgentId, c.UserLevel, c.LastLoginTime, c.RegTime, cw.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
	  FROM Customer c
		LEFT JOIN CustWallet cw ON c.CustId = cw.CustId
	  WHERE c.AgentId > 0
		AND c.RegTime >= fromDate;

  SELECT DISTINCT c.CustId, s.SiteId, s.SiteName, c.UserName, c.Userpwd, c.CurrencyId, c.UserLang, c.ActStatus, c.AgentId, c.AllAgentId, c.UserLevel, c.LastLoginTime, c.RegTime, c.FirstDepositTime, c.IsTest, c.IsKyc, c.IsRisk, c.Status
    FROM tmp_Customer c
      INNER JOIN ServerInfo s ON s.SiteId = c.SiteId
  ORDER BY s.SiteId, s.SiteName;
END

//
DELIMITER ;

GRANT EXECUTE ON PROCEDURE N88_CustomerSel TO ''@'%';