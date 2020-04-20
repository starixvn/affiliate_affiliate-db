USE Siebog;

DROP TABLE IF EXISTS AffCustomer;
CREATE TABLE AffCustomer (
  custId INT NOT NULL,
  affId INT NOT NULL,
  PRIMARY KEY (custId)
);