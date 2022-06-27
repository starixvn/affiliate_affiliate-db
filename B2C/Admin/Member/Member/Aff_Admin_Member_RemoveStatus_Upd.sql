/*<info serverAlias="DBAFFN88-Affiliate_N88,DBAFFN8B-Affiliate_N8B,DBAFFN8G-Affiliate_N8G" executers="bodbAdminNet" isFunction="0" isNested="0"></info>*/
ALTER PROCEDURE [dbo].[Aff_Admin_Member_RemoveStatus_Upd]
	@UserId			INT
	,@CustId		INT
	,@IsRemoved		BIT
	,@IsInclude		BIT
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
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MonthDate SMALLDATETIME, @TimeZone INT = 0, @FromDate DATETIME, @ToDate DATETIME, @CurrenDate DATETIME =  GETDATE()

	SELECT @TimeZone = dbo.Aff_f_GetSetting('TimeZone')

	IF @IsInclude = 0 
	BEGIN
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0), @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromDate))
	END

	IF @IsRemoved = 1 AND @IsInclude = 1
	BEGIN
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0), @ToDate = @CurrenDate
	END
	
	IF EXISTS (
		SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK)
		WHERE mr.CustId = @CustId AND mr.FromDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0) AND mr.FromDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate) + 1, 0)
	)
	BEGIN
		DELETE mr WITH(ROWLOCK, UPDLOCK)
		FROM MemberRemoval mr 
		WHERE mr.CustId = @CustId AND mr.FromDate >= DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0) AND mr.FromDate < DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate) + 1, 0)
	END

	INSERT INTO dbo.MemberRemoval (CustId, RemovedDate, FromDate, ToDate, IsInclude, RemovedBy)
	VALUES (@CustId, DATEADD(HOUR, 4 + @TimeZone, @CurrenDate), DATEADD(HOUR, 4 + @TimeZone, @FromDate), DATEADD(HOUR, 4 + @TimeZone, @ToDate), @IsInclude, @UserId)

	DECLARE @SPName VARCHAR(200), @NewData NVARCHAR(MAX)
	SELECT @SPName = OBJECT_NAME(@@PROCID)
	SELECT @NewData = 'Update remove status: CustId = ' + CONVERT(VARCHAR(20), @Custid) + 'IsRemoved = ' + CONVERT(VARCHAR(20), @IsRemoved) + ' IsInclude = ' + CONVERT(VARCHAR(20), @IsInclude)
	
	EXEC dbo.Aff_UserLog_RunSP_Detail_WriteLog
		@UserId		= @UserId
		,@AffId		= 0
		,@SPName	= @SPName
		,@NewData	= @NewData
		,@IP		= @IP
	
END
GO