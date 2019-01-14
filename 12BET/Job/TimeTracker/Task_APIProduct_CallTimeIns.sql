/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_CallTimeIns]
	@ProductId	INT,
	@Currency	INT = NULL,
    @CallTime   DATETIME,
	@ErrCode	INT = 0 OUTPUT,
	@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS
BEGIN
    SET NOCOUNT ON

    INSERT INTO dbo.APIProduct_TimeTracker (ProductId, Currency, CallTime)
    VALUES (@ProductId, @Currency, @CallTime)

    IF @@ERROR <> 0
	BEGIN
		SELECT @ErrCode = 103, @ErrMsg = 'Insert failed'
		RETURN
	END
END