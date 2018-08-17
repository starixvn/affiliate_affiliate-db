/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Aff_User_ProductsProgram_Sel]
AS

/*
	Created: 20180601@Percy
	DB: DBAFF12BET-Affiliate_12BET
	Task: User site - Products - List of offered products

	Revisions:
		- 20180601@Percy: Initialize SP [RedmineID: #87923]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @isTest BIT
	SELECT  @isTest = dbo.f_Aff_CheckSPVersion(@@PROCID)

	-- SportsBook part
	SELECT
		ProductName AS ProductNameEN,
		ProductName AS ProductNameCS,
		ProductName AS ProductNameCH,
		ProductName AS ProductNameID,
		ProductName AS ProductNameVN,
		ProductName AS ProductNameTH,
		ProductName AS ProductNameKO,
		ProductName AS ProductNameES,
		ProductName AS ProductNameJP,
		ProductName AS ProductNameHIEN,
		ProductName AS ProductNameENEURO,
		Description AS DescriptionEN,
		Description AS DescriptionCS,
		Description AS DescriptionCH,
		Description AS DescriptionID,
		Description AS DescriptionVN,
		Description AS DescriptionTH,
		Description AS DescriptionKO,
		Description AS DescriptionES,
		Description AS DescriptionJP,
		Description AS DescriptionHIEN,
		Description AS DescriptionENEURO
	FROM dbo.ProductsProgram WITH (NOLOCK)
	WHERE IsCasino = 0
		AND IsTest <= @isTest
		AND IsDeleted = 0

	-- Casino part
	SELECT
		-- ProductName
		--pn.c.value('@EN', 'NVARCHAR(200)')		AS ProductNameEN,
		--pn.c.value('@CS', 'NVARCHAR(200)')		AS ProductNameCS,
		--pn.c.value('@CH', 'NVARCHAR(200)')		AS ProductNameCH,
		--pn.c.value('@ID', 'NVARCHAR(200)')		AS ProductNameID,
		--pn.c.value('@VN', 'NVARCHAR(200)')		AS ProductNameVN,
		--pn.c.value('@TH', 'NVARCHAR(200)')		AS ProductNameTH,
		--pn.c.value('@KO', 'NVARCHAR(200)')		AS ProductNameKO,
		--pn.c.value('@ES', 'NVARCHAR(200)')		AS ProductNameES,
		--pn.c.value('@JP', 'NVARCHAR(200)')		AS ProductNameJP,
		--pn.c.value('@HIEN', 'NVARCHAR(200)')	AS ProductNameHIEN,
		--pn.c.value('@ENEURO', 'NVARCHAR(200)')	AS ProductNameENEURO,
		-- SubProductName
		spn.c.value('@EN', 'NVARCHAR(200)')		AS SubProductNameEN,
		spn.c.value('@CS', 'NVARCHAR(200)')		AS SubProductNameCS,
		spn.c.value('@CH', 'NVARCHAR(200)')		AS SubProductNameCH,
		spn.c.value('@ID', 'NVARCHAR(200)')		AS SubProductNameID,
		spn.c.value('@VN', 'NVARCHAR(200)')		AS SubProductNameVN,
		spn.c.value('@TH', 'NVARCHAR(200)')		AS SubProductNameTH,
		spn.c.value('@KO', 'NVARCHAR(200)')		AS SubProductNameKO,
		spn.c.value('@ES', 'NVARCHAR(200)')		AS SubProductNameES,
		spn.c.value('@JP', 'NVARCHAR(200)')		AS SubProductNameJP,
		spn.c.value('@HIEN', 'NVARCHAR(200)')	AS SubProductNameHIEN,
		spn.c.value('@ENEURO', 'NVARCHAR(200)') AS SubProductNameENEURO,
		-- Settings
		s.c.value('@IsLive', 'BIT')				AS IsLive,
		s.c.value('@IsSlot', 'BIT')				AS IsSlot,
		s.c.value('@IsProgressive', 'BIT')		AS IsProgressive,
		s.c.value('@IsTableCard', 'BIT')		AS IsTableCard,
		s.c.value('@IsScratchAracade', 'BIT')	AS IsScratchAracade,
		s.c.value('@IsVideoPoker', 'BIT')		AS IsVideoPoker
	FROM
	(
		SELECT
			CONVERT(XML, ISNULL(NULLIF(ProductNameLanguages, N''), N'<ProductName />')) AS ProductName,
			CONVERT(XML, ISNULL(NULLIF(SubProductNameLanguages, N''), N'<SubProductName />')) AS SubProductName,
			CONVERT(XML, ISNULL(NULLIF(Settings, N''), N'<Settings />')) AS Settings
		FROM dbo.ProductsProgram WITH (NOLOCK)
		WHERE IsCasino = 1
			AND IsTest <= 1
			AND IsDeleted = 0
	) AS p
		--CROSS APPLY p.ProductName.nodes('ProductName') AS pn(c)
		CROSS APPLY p.SubProductName.nodes('SubProductName') AS spn(c)
		CROSS APPLY p.Settings.nodes('Settings') AS s(c)
	
END
GO