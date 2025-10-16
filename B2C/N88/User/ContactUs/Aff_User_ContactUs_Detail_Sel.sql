/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_User_ContactUs_Detail_Sel]
AS

/*
	Created: 20251009@Danny
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task:  Get information in Contact Us Page 

	Revisions:
		- 20251009@Danny: Initialize SP [RedmineID: #227560]

	Param's Explanation:

	EXEC Aff_User_ContactUs_Detail_Sel 

*/

BEGIN
	SET NOCOUNT ON
	; WITH c AS 
	(
		SELECT 'Affiliate_N88' AS DbName,'bn-BD' AS MarketID,'BD' AS CountryCode,'{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}' AS ExtraInfo
		UNION ALL SELECT 'Affiliate_N88','en-US','BD','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','en-US','ID','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','id-ID','ID','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','en-US','IN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','hi-IN','IN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','en-US','MY','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','ms-MY','MY','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','zh-CN','MY','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','en-US','TH','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','th-TH','TH','{"Email":"winston.chau@nexcel.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','en-US','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily"}'
		UNION ALL SELECT 'Affiliate_N88','vi-VN','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/nova88affiliate","Whatsapp":"https://cli.re/nova88daily","Zalo":"(+66) 991 915 095"}'
	
		UNION ALL SELECT 'Affiliate_N8B','en-US','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://cli.re/bwing-affiliate","Whatsapp":"https://cli.re/bwingdaily"}'
		UNION ALL SELECT 'Affiliate_N8B','vi-VN','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://cli.re/bwing-affiliate","Whatsapp":"https://cli.re/bwingdaily"}'

		UNION ALL SELECT 'Affiliate_N8G','en-US','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/goal123_aff","Whatsapp":"https://cli.re/goal123daily"}'
		UNION ALL SELECT 'Affiliate_N8G','vi-VN','VN','{"Email":"winston.chau@starixsoft.com","Telegram":"https://t.me/goal123_aff","Whatsapp":"https://cli.re/goal123daily","Zalo":"(+66) 991 920 083"}'
	)

	SELECT  t.CountryCode, 
			t.CountryName, 
			t.MarketID, 
			t.MarketName,
			JSON_VALUE(ExtraInfo, '$.Email')     AS Email,
			JSON_VALUE(ExtraInfo, '$.Telegram')  AS Telegram,
			JSON_VALUE(ExtraInfo, '$.Whatsapp')  AS Whatsapp,
			JSON_VALUE(ExtraInfo, '$.Zalo')		 AS Zalo
	FROM  c 
	INNER JOIN TargetCountry t  WITH(NOLOCK) ON c.MarketID = t.MarketID AND c.CountryCode = t.CountryCode
	WHERE c.DbName = DB_NAME()
END


