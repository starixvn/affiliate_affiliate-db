/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_ClickStatisticsPatterns_Upd]
	@ClickIDs		VARCHAR(MAX)
	,@IsExcluded	BIT
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT

AS
/*
	Created: 20251022@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Update ClickStatistics IsExcluded column [RedmineId: #241768]

	Revisions:  
		- 20251022@Sophia: Initialize SP to update IsExcluded column [RedmineID: #241768]

*/
BEGIN
	SET NOCOUNT ON;

	BEGIN TRY

		IF @IsExcluded IS NULL
		BEGIN
			SET @ErrCode = 302;
			SET @ErrMsg = 'IsExcluded parameter is required!';
			RETURN;
		END

		-- Create temp table to store ClickIDs
		CREATE TABLE #TempClickIDs (
			ClickId BIGINT
		);

		-- Insert ClickIDs into temp table (split comma-separated values)
		INSERT INTO #TempClickIDs (ClickId)
		SELECT CAST(value AS BIGINT)
		FROM STRING_SPLIT(@ClickIDs, ',')
		WHERE TRIM(value) != '';

		-- Check if any ClickIDs were provided
		IF NOT EXISTS (SELECT 1 FROM #TempClickIDs)
		BEGIN
			SET @ErrCode = 303;
			SET @ErrMsg = 'No valid ClickIDs provided!';
			DROP TABLE #TempClickIDs;
			RETURN;
		END

		-- Update ClickStatistics table
		UPDATE cs
		SET IsExcluded = @IsExcluded
		FROM dbo.ClickStatistics cs
		INNER JOIN #TempClickIDs t ON cs.ClickId = t.ClickId;

		-- Get the number of rows affected
		DECLARE @RowsAffected INT = @@ROWCOUNT;

		-- Clean up temp table
		DROP TABLE #TempClickIDs;

		-- Return success message with affected rows count
		SET @ErrCode = 0;
		SET @ErrMsg = CAST(@RowsAffected AS NVARCHAR(10)) + ' record(s) updated successfully.';

	END TRY
	BEGIN CATCH
		
		-- Clean up temp table if it exists
		IF OBJECT_ID('tempdb..#TempClickIDs') IS NOT NULL
			DROP TABLE #TempClickIDs;

		-- Set error information for update failures
		SET @ErrCode = 304;
		SET @ErrMsg = 'Update ClickStatistics failed: ' + ERROR_MESSAGE();
		RETURN;
	END CATCH
		
END
GO