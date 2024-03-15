/*<info serverAlias="DBAFFYASHBET-Affiliate_YashBet" executers="wsv_nap,wsv_alp,wsv_alpv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_PaymentMethod_Sel]
	@MinAmount MONEY = 0 OUTPUT
AS

/*
	Created: 20240115@Sally
	DB: DBAFFYASHBET-Affiliate_YashBet
	Task: Payment Information - List supported payment method

	Revisions:
		- 20240115@Sally: Initialize SP [RedmineID: #198909]

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