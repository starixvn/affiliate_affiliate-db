/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet,bodbDownlineNet,bodbDownlineNetView" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_PaymentMethod_Sel]
	@MinAmount MONEY = 0 OUTPUT
AS

/*
	Created: 20200220@Percy
	DB: DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G
	Task: Payment Information - List supported payment method

	Revisions:
		- 20200220@Percy: Initialize SP [RedmineID: #128775]
*/

BEGIN
	SET NOCOUNT ON

	SELECT @MinAmount = CONVERT(MONEY, SValue)
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'Payment_MinAmount'
	
	SELECT @MinAmount = ISNULL(@MinAmount, 0)

	DECLARE @PaymentMethod XML
	SELECT  @PaymentMethod = REPLACE(N'<root><r ID="' + REPLACE(SValue, ',', '" /><r ID="') + '" /></root>', ':', '" Name="')
	FROM dbo.SystemSettings WITH (NOLOCK)
	WHERE SName = 'Payment_Method'

	SELECT
		t.c.value('@ID', 'VARCHAR(20)') AS [PaymentId],
		t.c.value('@Name', 'VARCHAR(50)') AS [PaymentName]
	FROM @PaymentMethod.nodes('/root/r') AS t(c)
END
GO