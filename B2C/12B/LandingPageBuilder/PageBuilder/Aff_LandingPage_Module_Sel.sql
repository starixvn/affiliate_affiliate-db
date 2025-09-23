/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_LandingPage_Module_Sel]
(
	@ModuleTypes VARCHAR(100) = 'All'
)
AS
/*
	Created: 20250825@Sophia
	DB: DBAFF12B-Affiliate_12B
	Task: Select Landing Page Modules by Type

	Revisions:  
		- 20250825@Sophia: Initialize SP [RedmineID: #236797]
*/
BEGIN
	SET NOCOUNT ON;
	
	-- If @ModuleTypes is 'All', return all modules
	IF @ModuleTypes = 'All'
	BEGIN
		SELECT 
			ModuleId,
			ModuleName,
			ModuleType,
			NavigateTo,
			IsMultipleUpload,
			IsRequired,
			IsUnique
		FROM LandingPage_Module WITH (NOLOCK)
		WHERE StatusId = 1
		ORDER BY ModuleId ASC;
	END
	ELSE
	BEGIN
		-- Split comma-separated ModuleTypes and filter
		SELECT 
			ModuleId,
			ModuleName,
			ModuleType,
			NavigateTo,
			IsMultipleUpload,
			IsRequired,
			IsUnique
		FROM LandingPage_Module WITH (NOLOCK)
		WHERE  StatusId = 1
			AND ModuleType IN (
				SELECT CAST(value AS SMALLINT)
				FROM STRING_SPLIT(@ModuleTypes, ',')
				WHERE TRIM(value) <> ''
			)
		ORDER BY ModuleId ASC;
	END
END
GO