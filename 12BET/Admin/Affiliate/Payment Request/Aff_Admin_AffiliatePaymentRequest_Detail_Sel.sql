/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Detail_Sel]
	@TransId BIGINT
AS

/*
	Created: 20160614@Percy
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin - Affiliate - Payment Request - View payment request by TransID

	Revisions:
		- 20190614@Percy: Initialize SP [RedmineID: #109008]
		- 20200731@Percy: Restructure admin role [RedmineID: #121975]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		a.TransId
		,a.AffId
		,a.TransDate
		,a.CompletedDate
		,a.RefId
		,a.Status
		,a.Description AS TransDesc
		,ai.UserName
		,ad.Player_Username AS UserName2
		,ad.PreferredPayment
		,ad.PreferredLanguage
		,ABS(a.Amount) AS Amount
		,ap.AdminDesc
		,ap.AffDesc
		,ai.Email
		,ai.FirstName
		,ai.LastName
		,ad.neteller_accountId
		,ad.moneybookers_email
		,ad.wire_bankname
		,ad.wire_bankaddress
		,ad.wire_swiftcode
		,ad.wire_accountname
		,ad.wire_accountno
		,ad.Cheque_FullName
		,ad.cheque_address
		,ad.cheque_city
		,ad.cheque_state
		,ad.cheque_postal
		,ad.cheque_country
		,u.UserName AS AdminName
	FROM dbo.AffTrans a WITH (NOLOCK)
		INNER JOIN dbo.AffPayout ap WITH (NOLOCK) ON a.RefID = ap.RefID
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON a.AffID = ai.AffID
		INNER JOIN dbo.AffDetail ad WITH (NOLOCK) ON ai.AffID = ad.AffID
		LEFT JOIN dbo.Users u WITH (NOLOCK) ON a.Creator = u.CustId
	WHERE a.TransID = @TransId
END
GO