/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_AffiliatePaymentRequest_Detail_Sel]
	@TransId BIGINT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Affiliate - Payment Request - View payment request by TransId

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]
		- 20250404@Sally: Enhance get BBF by TimeZone [RedmineID: #222352]
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
		,DATEADD(HOUR, 12, at.TransDate) AS TransDate -- GMT+8
		,DATEADD(HOUR, 12, at.CompletedDate) AS CompletedDate -- GMT+8
		,au.UserName AS Creator
		,ap.AdminDesc
		,ap.AffDesc
	FROM dbo.AffTrans at WITH (NOLOCK)
		INNER JOIN dbo.AffPayout ap WITH (NOLOCK) ON at.RefID = ap.RefID
		LEFT JOIN dbo.TpExchange t WITH (NOLOCK) ON ap.Player_Currency = t.TpExchangeId
		INNER JOIN dbo.Exchange e WITH (NOLOCK) ON ISNULL(t.ExchangeId, ap.Player_Currency) = e.ExchangeId
		INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON at.AffID = ai.AffID
		LEFT JOIN dbo.Affiliate_User au WITH (NOLOCK) ON at.creator = au.custid
	WHERE at.TransId = @TransId
END
GO