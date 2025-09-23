/*<info serverAlias="DBAFF12B-Affiliate_12B" selecters="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_GetTargetLanguageCode]()
RETURNS TABLE
AS
/*
    Created: 20250915@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Return mapping table of ShortedCode to TargetLanguageCode for landing page builder
    Output: Table with ShortedCode and corresponding TargetLanguageCode
    Revisions:
        - 20250915@Sophia: Initial version [RedmineID: #236797]
        - 20250917@Sophia: Removed hardcoded values, kept only hitg mapping [RedmineID: #236797]
    Example:
        SELECT * FROM dbo.Aff_f_GetTargetLanguageCode()
  
*/
RETURN
    SELECT ShortedCode, TargetLanguageCode
    FROM (VALUES
        ('hitg', 'te')
    ) AS Codes(ShortedCode, TargetLanguageCode);
GO
