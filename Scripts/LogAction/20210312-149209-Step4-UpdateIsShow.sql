/*<info serverAlias="DBAFF12BET-Affiliate_12BET"></info>*/
/*
	Created: 20210312@Malcolm
	DB: DBAFF12BET-Affiliate_12BET
	Task: Update log action
*/

DECLARE @LogAction TABLE (SPName NVARCHAR(100), Description NVARCHAR(200))

INSERT INTO @LogAction (SPName, Description)
VALUES 
 ('Aff_AffiliateUpdPwd', 'Affiliate updates password')
 ,('Aff_Admin_AffiliateClosed_Upd','Admin updates affiliate close status')
 ,('Aff_Admin_AffiliatePaymentRequest_Upd', 'Admin updates payment request')
 ,('Aff_Admin_AffiliateStatus_Upd', 'Admin approves pending afifliate')
  ,('Aff_Admin_Adjustment_Upd', 'Adjustment (Upload)')
  ,('Aff_User_PaymentRequest_Upd','Affiliate cancels payment request')
  ,('Aff_Admin_Affiliate_Password_Upd','Admin updates affiliate password')
  ,('Aff_Admin_AffiliateInfo_Upd','Admin updates user information')
  ,('Aff_User_UserInfoUpd','Affiliate updates user information')
 ,('Aff_User_UserInfoUpd','Affiliate updates user information')

UPDATE l WITH(ROWLOCK)
	SET l.Description = t.Description
FROM LogAction l
	INNER JOIN @LogAction t ON t.SPName = l.SPName

UPDATE LogAction WITH(ROWLOCK)
	SET IsShow = 0
WHERE SPName = 'Aff_AffiliateUpdInfo'
