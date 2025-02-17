/*<info serverAlias="DB12B-bodb_12B"></info>*/
/*
	Created: 20250213@Eddie
	DB: DB12B-bodb_12B
	Task: Initial data for bodb_12B DB [RedmineId : #212201]

*/
USE bodb_12B
GO

/****** Object: Table [SystemSettings] ******/
DECLARE @lastmonth DATE, @beginofmonth DATETIME
SELECT @beginofmonth = DATEADD(MONTH, DATEDIFF(MONTH, 0, GETDATE()), 0)
SELECT @lastmonth = DATEADD(MONTH, -1, @beginofmonth)

INSERT INTO dbo.SystemSettings (SName, SValue)
SELECT t.SName, t.SValue
FROM (
		SELECT 'ArchiveData_Date', CONVERT(VARCHAR(200), @lastmonth, 120)
		UNION ALL
	    SELECT 'UpdatedCustomer_Date', CONVERT(VARCHAR(200), @beginofmonth, 120)
		UNION ALL
	    SELECT 'TimeZone', '-4'
		UNION ALL
	    SELECT 'Deposit_CutOffDate', '2025-02-13 00:00:00'
) AS t(SName, SValue)
	LEFT JOIN dbo.SystemSettings s WITH (NOLOCK) ON s.SName = t.SName
WHERE s.SName IS NULL
GO


/****** Object: Table [TpExchange] ******/
INSERT INTO dbo.TpExchange (TpExchangeId, ExchangeId)
SELECT t.TpExchangeId, t.ExchangeId
FROM (
	VALUES (74, 97)
		  ,(72, 3)
		  ,(3, 3)
) AS t(TpExchangeId, ExchangeId)
	LEFT JOIN dbo.TpExchange p WITH (NOLOCK) ON p.TpExchangeId = t.TpExchangeId
											AND p.ExchangeId = t.ExchangeId
WHERE p.TpExchangeId IS NULL
   OR p.ExchangeId IS NULL
GO


/****** Object: Table [TpGameType] ******/
INSERT INTO dbo.TpGameType (Type, TypeName)
SELECT t.Type, t.TypeName
FROM (
	  VALUES (1,   N'OW Sports')
			,(2,   N'OW Number Game')
			,(3,   N'OW Virtual Sports')
			,(4,   N'OW RNG')
			,(5,   N'OW Keno')
			,(6,   N'Allbet L.Casino')
			,(7,   N'PP RNG')
			,(8,   N'AG L.Casino')
			,(9,   N'SA L.Casino')
			,(10,  N'DG L.Casino')
			,(11,  N'GPI RNG')
			,(12,  N'YL Fishing')
			,(13,  N'Joker RNG')
			,(14,  N'YGG RNG')
			,(15,  N'SG RNG')
			,(16,  N'PP L.Casino')
			,(17,  N'PG RNG')
			,(18,  N'Sexy L.Casino')
			,(19,  N'OW Lottery')
			,(20,  N'OW Togel 4D')
			,(21,  N'OW Card Club')
			,(22,  N'OW Virtual Games')
			,(23,  N'OW Table Game')
			,(24,  N'OW Virtual Sports 2')
			,(25,  N'OW Saba Club')
			,(26,  N'OW Macau Game')
			,(27,  N'Cockfighting')
			,(28,  N'EBet L.Casino')
			,(29,  N'CQ9 RNG')
			,(30,  N'AWC Cockfighting')
			,(31,  N'SG Fishing')
			,(32,  N'WM L.Casino')
			,(33,  N'918 RNG')
			,(34,  N'Mega  RNG')
			,(35,  N'One789 Lottery')
			,(36,  N'One789 Lottery789')
			,(37,  N'One789 L.Casino')
			,(38,  N'OW China Lottery')
			,(39,  N'Iconic RNG')
			,(40,  N'Iconic Fish')
			,(41,  N'OneGaming Poker')
			,(42,  N'V8 Poker')
			,(44,  N'CQ9 Fishing')
			,(45,  N'N2 Live Casino')
			,(46,  N'PT RNG')
			,(47,  N'V8 Poker (No Revenue)')
			,(48,  N'PT Live Casino')
			,(49,  N'BTI Sports')
			,(50,  N'AMB Poker')
			,(51,  N'9W Sports')
			,(52,  N'KM Poker')
			,(53,  N'JILI RNG')
			,(54,  N'TCG SEA Lottery')
			,(55,  N'TCG VN Lottery')
			,(56,  N'JILI Fish')
			,(57,  N'MG RNG')
			,(58,  N'MG L.Casino')
			,(59,  N'OW Vgaming')
			,(60,  N'MP Poker')
			,(61,  N'MP Poker (No Revenue)')
			,(62,  N'OW Bitcoin')
			,(63,  N'EVO L.Casino')
			,(64,  N'Netent RNG')
			,(65,  N'RedTiger RNG')
			,(66,  N'Joker Fishing')
			,(67,  N'AP RNG')
			,(68,  N'HB RNG')
			,(69,  N'SBSW Sports')
			,(70,  N'SBSW Number Game')
			,(71,  N'SBSW Virtual Sports')
			,(72,  N'SBSW Virtual Sports 2')
			,(73,  N'SBSW Keno')
			,(74,  N'SBSW Lottery')
			,(75,  N'SBSW Table Game')
			,(76,  N'AMB RNG')
			,(77,  N'SBO Sports')
			,(78,  N'SBO Games')
			,(79,  N'SBO L.Casino')
			,(80,  N'OW LG Virtual Sports')
			,(81,  N'SBO Virtual Sports')
			,(82,  N'Skywind RNG')
			,(83,  N'OW Max Game')
			,(84,  N'Skywind L.Casino')
			,(85,  N'Skywind Fish')
			,(86,  N'SimplePlay RNG')
			,(87,  N'Crypto Sports')
			,(88,  N'GPI Keno')
			,(89,  N'GPI So De')
			,(90,  N'GPI Thai Lottery')
			,(91,  N'GPI Fast3')
			,(93,  N'Yeebet L.Casino')
			,(94,  N'BG L.Casino')
			,(95,  N'SBSW Vgaming')
			,(96,  N'SBSW Card Club')
			,(97,  N'TFGaming Esports')
			,(98,  N'Endorphina RNG')
			,(99,  N'Nextspin RNG')
			,(100, N'PlayTech RNG')
			,(101, N'PlayTech L.Casino')
			,(102, N'IM E-Sports')
			,(103, N'IM Sports')
			,(104, N'SPRIBE RNG')
			,(105, N'PNG RNG')
			,(106, N'FaChai RNG')
			,(107, N'Pegasus RNG')
			,(108, N'BNG RNG')
			,(109, N'SG Table')
			,(110, N'Grand Dragon 4D')
			,(111, N'NLC RNG')
			,(112, N'Amigo RNG')
			,(113, N'MaxGame Poker')
			,(114, N'93Connect Games')
			,(115, N'GA Cockfighting')
			,(116, N'Won L.Casino')
			,(117, N'CQ9 WCC')
			,(119, N'SabaPlay Poker')
			,(120, N'UuSlots RNG')
			,(121, N'Live22 RNG')
			,(122, N'FastSpin RNG')
			,(123, N'Dragon Gaming RNG')
			,(124, N'PG2 RNG')
			,(125, N'Eday')
) AS t(Type, TypeName)
	LEFT JOIN dbo.TpGameType p WITH (NOLOCK) ON p.Type = t.Type
WHERE p.Type IS NULL
GO