/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_PaymentMethod_Sel]
	@MinAmount MONEY = 0 OUTPUT
AS

/*
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Payment Information - List supported payment method

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

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