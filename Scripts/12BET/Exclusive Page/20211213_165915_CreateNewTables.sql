/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
/*
	Created: 20211213@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
*/
CREATE TABLE dbo.OfferPage
(
	PageId				INT IDENTITY(1, 1)
	,FileName			NVARCHAR(200)
	,FileSize			INT
	,Language			NVARCHAR(50)
	,UploadDate			DATETIME
	,EffectiveFromDate	DATETIME
	,EffectiveToDate	DATETIME
)

CREATE TABLE dbo.OfferAffiliate
(
	PageId INT
	,AffId INT
)