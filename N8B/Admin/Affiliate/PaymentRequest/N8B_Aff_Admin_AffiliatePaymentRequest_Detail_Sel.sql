/*<info serverAlias="DBAFFN8B-Affiliate_N8B" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Detail_Sel]
	@TransId BIGINT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN8B-Affiliate_N8B
	Task: Admin - Affiliate - Payment Request - View payment request by TransId

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT
		at.TransId
		,at.AffId
		,ai.UserName AS AffName
		,ai.Email
		,ai.FirstName
		,ai.LastName
		,ap.PreferredPayment
		,ABS(ap.Amount) AS Amount
		,ABS(ap.AffPayout) AS TransAmount
		,ABS(ap.AffPayout * 1.0 * e.MultipliedBy) AS OriginalTransAmount
		,CASE WHEN ap.Player_Currency = 20 THEN 'UUS' ELSE ap.Player_CurrencyCode END AS TransCurrencyCode
		,ap.Player_Username AS PlayerUsername
		,CASE WHEN at.Status = 'Pending' THEN 'Processing' ELSE at.Status END AS Status
		,at.TransDate
		,at.CompletedDate
		,au.UserName AS Creator
		,ap.AdminDesc
		,ap.AffDesc
	FROM dbo.AffTrans at WITH (NOLOCK)
		INNER JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON ap.Player_Currency = e.ExchangeId
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON at.AffID = ai.AffID
		LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.creator = au.custid
	WHERE at.TransId = @TransId
END
GO