/*<info serverAlias="DBAFFN8G-Affiliate_N8G"></info>*/

/*
	Created: 20200514@Percy
	DB: DBAFFN8G-Affiliate_N8G
	Task: Update supported products
*/

TRUNCATE TABLE dbo.Products
GO

INSERT INTO dbo.Products (ProductId,ProductName,ProductPrefix,IsIBC,Enabled,IsTest,ReleasedDate,RefProductId,DataSource)
VALUES
	(1,'OW Sports','',0,1,0,'2020-05-01',1,'TpBetRecord')
	,(2,'OW Number Game','',0,1,0,'2020-05-01',2,'TpBetRecord')
	,(3,'OW Virtual Sports','',0,1,0,'2020-05-01',3,'TpBetRecord')
	,(4,'OW RNG','',0,1,0,'2020-05-01',4,'TpBetRecord')
	,(5,'OW Keno','',0,1,0,'2020-05-01',5,'TpBetRecord')
	,(6,'Allbet L.Casino','',0,1,0,'2020-05-01',6,'TpBetRecord')
	,(7,'PP RNG','',0,1,0,'2020-05-01',7,'TpBetRecord')
	,(8,'AG L.Casino','',0,1,0,'2020-05-01',8,'TpBetRecord')
	,(9,'SA L.Casino','',0,1,0,'2020-05-01',9,'TpBetRecord')
	,(10,'DG L.Casino','',0,1,0,'2020-05-01',10,'TpBetRecord')
	,(11,'GPI RNG','',0,1,0,'2020-05-01',11,'TpBetRecord')
	,(12,'YL Fishing','',0,1,0,'2020-05-01',12,'TpBetRecord')
	,(13,'Joker RNG','',0,1,0,'2020-05-01',13,'TpBetRecord')
	,(14,'YGG RNG','',0,1,0,'2020-05-01',14,'TpBetRecord')
	,(15,'SG RNG','',0,1,0,'2020-05-01',15,'TpBetRecord')
	,(16,'PP L.Casino','',0,1,0,'2020-05-01',16,'TpBetRecord')
GO

DELETE dbo.DeductionSetting WITH (ROWLOCK, UPDLOCK)
WHERE DeductionId = 10 AND ProductId > 16
GO

DELETE dbo.DeductionSettingHistory WITH (ROWLOCK, UPDLOCK)
WHERE MonthDate = '2020-05-31' AND DeductionId = 10 AND ProductId > 16
GO