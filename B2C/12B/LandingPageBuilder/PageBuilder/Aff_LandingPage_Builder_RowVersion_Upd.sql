/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="1"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Builder_RowVersion_Upd]
    @PageIds VARCHAR(MAX),
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created: 20250915@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Update RowVersion by updating Creator with its own value
    Revisions:
        - 20250915@Sophia: Initial version [RedmineID: #236797]

    Purpose: Update RowVersion column by performing a self-update.
             This allows detection of changes through the RowVersion timestamp.
*/
BEGIN
    SET NOCOUNT ON;

    -- =========================
    -- Validate required parameters
    -- =========================
    IF ISNULL(@PageIds, '') = ''
    BEGIN
        SELECT @ErrCode = 100, @ErrMsg = N'PageIds is required!';
        RETURN;
    END

    -- =========================
    -- Update to trigger RowVersion change
    -- =========================
    BEGIN TRY
        UPDATE b WITH (ROWLOCK)
        SET Creator = b.Creator -- Self-update to trigger RowVersion
        FROM dbo.LandingPage_Builder b
        WHERE b.PageId IN (SELECT value FROM STRING_SPLIT(@PageIds, ','));

    END TRY
    BEGIN CATCH
        SELECT 
            @ErrCode = 101,
            @ErrMsg = 'There was an error while updating RowVersion: ' + ERROR_MESSAGE();
        RETURN;
    END CATCH
END;
GO
