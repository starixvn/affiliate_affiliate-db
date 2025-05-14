/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Member_RemoveStatus_Upd]
	@UserId			INT
	,@CustId		INT
	,@FromDate		SMALLDATETIME
	,@IP			VARCHAR(20)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*
	Created: 20220627@Malcolm
	DB: DBAFF12BET.Affiliate_N88
	Task: Admin - Member - Active Member - Check Status

	Revisions:
		- 20220627@Malcolm: Initialize SP [RedmineID: #118992]
		- 20250424@Sally: Remove and Exclude from Commission Calculation [RedmineID: #224335]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MonthDate SMALLDATETIME
        ,@TimeZone INT = 0
        ,@CurrenDate DATETIME
        ,@CommissionDate SMALLDATETIME
        ,@ToDate SMALLDATETIME

    -- Check permission
	EXEC dbo.Aff_Con_CheckPermission
		@CustId		= @UserId,
		@FuncName	= '[Player]',
		@ErrCode	= @ErrCode OUTPUT,
		@ErrMsg		= @ErrMsg OUTPUT
	
	IF @ErrCode <> 0
		RETURN

	SELECT @CommissionDate = dbo.Aff_f_GetSetting('AFF_CommissionDate')
	SELECT @TimeZone       = dbo.Aff_f_GetSetting('TimeZone')
	SELECT @CurrenDate     =  DATEADD(HOUR, 4 + @TimeZone, GETDATE())
    SELECT @ToDate         = '2079-06-06'

    IF @FromDate <= @CommissionDate
    BEGIN
        SET @ErrMsg = 'The selected date cannot be earlier than the latest billing date'
        SET @ErrCode = 230
        RETURN
    END

    IF EXISTS (
        SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
        WHERE mr.CustId = @CustId AND DATEDIFF(MONTH, mr.RemovedDate, @CurrenDate) = 0
    )
    BEGIN
        UPDATE mr WITH(ROWLOCK)
            SET mr.RemovedDate = @CurrenDate
                ,mr.FromDate = @FromDate
                ,mr.ToDate = @ToDate
                ,mr.RemovedBy = @UserId
        FROM MemberRemoval mr
        WHERE mr.CustId = @CustId AND DATEDIFF(MONTH, mr.RemovedDate, @CurrenDate) = 0
    END
    ELSE
    BEGIN	
        INSERT INTO dbo.MemberRemoval (CustId, RemovedDate, FromDate, ToDate, RemovedBy)
        VALUES (@CustId, @CurrenDate, @FromDate, @ToDate, @UserId)
    END

    UPDATE dbo.MemberInfo WITH(ROWLOCK)
        SET IsRemoved = 1
    WHERE CustId = @CustId
        AND IsRemoved = 0

    DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
    SELECT @SPName = OBJECT_NAME(@@PROCID)
    SELECT @NewData = 'Update remove status: CustId = ' + CONVERT(VARCHAR(20), @Custid) + 'IsRemoved = 1'

    EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
        @UserId		= @UserId
        ,@AffId		= 0
        ,@SPName	= @SPName
        ,@NewData	= @NewData
        ,@IP		= @IP
END
GO