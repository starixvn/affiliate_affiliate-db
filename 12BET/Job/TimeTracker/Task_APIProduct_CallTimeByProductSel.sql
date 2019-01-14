/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_APIProduct_CallTimeByProductSel]
	@ProductId	INT,
	@Currency	INT = NULL
AS
BEGIN
    SET NOCOUNT ON

    SELECT TOP 1 CallTime
    FROM dbo.APIProduct_TimeTracker WITH (NOLOCK)
    WHERE ProductId = @ProductId AND (Currency IS NULL OR Currency = @Currency)
    ORDER BY CallTime DESC
END