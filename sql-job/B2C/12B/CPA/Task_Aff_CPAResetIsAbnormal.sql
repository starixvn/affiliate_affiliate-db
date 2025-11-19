/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="" viewers="" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Task_Aff_CPAResetIsAbnormal]
    @CPADate DATE,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(4000) = NULL OUTPUT
AS
/*
    Created: 20250620@Sophia
    DB: DBAFF12B-Affiliate_12B
    Task: Reset IsAbnormal player for CPA calculation [Redmine: #230662]

    Revisions:
        - 20250620@Sophia: Initialize SP [Redmine: # 230662]
		- 20250930@Lewis: Enhance Auto Approved [RedmineID: #235601]
 
*/
BEGIN
    SET NOCOUNT ON;
    DECLARE @Todate DATETIME = '9999-12-31'

	DECLARE @TimeZone SMALLINT
	SELECT @TimeZone = CONVERT(SMALLINT, SValue) 
    FROM dbo.SystemSettings WITH (NOLOCK) 
    WHERE SName = 'TimeZone';

    -- Error handling: check input
    IF @CPADate IS NULL
    BEGIN
        SET @ErrCode = 100;
        SET @ErrMsg = N'CPADate is NULL.';
        RETURN
    END
    -- Reset IsAbnormal to Pending in MemberCPA if not abnormal by tag logic
    UPDATE m 
    SET m.StatusId = 0,
        m.Description = '',
        m.UpdatedDate = DATEADD(HOUR, @TimeZone, GETUTCDATE())
    FROM dbo.MemberCPA m WITH (UPDLOCK, ROWLOCK)
    INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON m.CustID = mi.CustID
    INNER JOIN dbo.CPAGroupSetting cgs WITH (NOLOCK) ON m.GroupId = cgs.GroupId AND cgs.ToDate = @Todate
    WHERE m.StatusId = 4
      AND mi.RegisteredDate >= DATEADD(DAY, (1 - cgs.ActiveDays - cgs.HoldingDays), @CPADate)
      AND mi.RegisteredDate < DATEADD(DAY, 1, @CPADate)
      AND NOT EXISTS (
          SELECT 1
          FROM STRING_SPLIT(mi.TagList, ',') t
          INNER JOIN bodb_12B.dbo.Tag tag WITH (NOLOCK) ON tag.Id = t.value
          WHERE tag.IsAbnormal = 1
      );
 
    -- At the end, set success code
    SET @ErrCode = 0;
    SET @ErrMsg = NULL;
END;
GO
