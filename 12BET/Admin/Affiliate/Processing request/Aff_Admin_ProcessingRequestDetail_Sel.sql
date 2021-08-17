/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE dbo.Aff_Admin_ProcessingRequestDetail_Sel
	@RequestId INT
AS

/*
	Created: 20210817@Malcolm
	DB: DBAFF12BET.Affiliate_12BET
	Task: Admin Site - Affiliate - Processing Request detail
	Revisions:
		- 20210817@Malcolm: Initialize SP [RedmineID: #159570]
*/

BEGIN
	SET NOCOUNT ON

	SELECT 
		pr.RequestId
		,ai.AffId
		,ai.UserName
		,pr.Creator
		,cr.UserName AS CreatedBy
		,pr.CreationDate
		,pr.LastModified
		,pr.SubmittedDate
		,pr.Deadline
		,pr.Approver
		,ap.UserName AS ApprovedBy
		,pr.ApprovalDate
		,pr.Status
		,pr.MarketID
		,m.MarketName
		,pr.PreferredPayment
		,pr.Player_Username
		,pr.PromotionMethod
		,pr.WebRank
		,pr.WebRegDate
		,pr.WebSMLanguage
		,pr.ServerCountry
		,pr.WebSMQuality
		,pr.WebSMType
		,pr.WebAdvAff
		,pr.TargetMarket
		,pr.AgentName
		,pr.ContactModeTime
		,pr.Remark
		,pr.Wire_BankName AS BankName
		,pr.Wire_BankAddress AS BankAddress
		,pr.Wire_SwiftCode AS SwiftCode 
		,pr.Wire_AccountName AS AccountName
		,pr.Wire_AccountNo AS AccountNo
	FROM dbo.ProcessingRequest pr WITH(NOLOCK)
		INNER JOIN dbo.AffInfo ai WITH(NOLOCK) ON ai.AffID = pr.AffId
		LEFT JOIN dbo.Users cr WITH(NOLOCK) ON cr.CustId = pr.Creator
		LEFT JOIN dbo.Users ap WITH(NOLOCK) ON ap.CustId = pr.Approver
		LEFT JOIN dbo.Market m WITH(NOLOCK) ON m.MarketID = pr.MarketID
	WHERE pr.RequestId = @RequestId

END
GO