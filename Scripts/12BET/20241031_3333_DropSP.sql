/*<info serverAlias="DBCTG-bodb02"></info>*/
/*
	Created: 20241031@Eddie
	DB: DBCTG-bodb02
	Task: Rename and Drop unused SPs
*/
USE bodb02
GO

-- Rename SPs 
EXEC sp_rename 'Aff_Admin_AffiliatePaymentRequest_Approve', 'DEL_Aff_Admin_AffiliatePaymentRequest_Approve'
GO


-- Drop SPs
DROP PROCEDURE DEL_Aff_Admin_AffiliatePaymentRequest_Approve
GO