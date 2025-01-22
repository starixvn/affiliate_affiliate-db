/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Member_RemoveStatus_Upd]
	@UserId			INT
	,@CustId		INT
	,@IsRemoved		BIT
	,@IsInclude		BIT
	,@IP			VARCHAR(50)
	,@ErrCode		INT = 0 OUTPUT
	,@ErrMsg		NVARCHAR(4000) = '' OUTPUT
AS

/*  
	Created: 20241118@Eddie
	DB: DBAFF12B-Affiliate_12B
	Task: Admin - Member - Active Member - Check Status

	Revisions:
		- 20241118@Eddie: Initialize SP [RedmineID: #212201]

*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MonthDate SMALLDATETIME, @TimeZone INT = 0, @FromDate DATETIME, @ToDate DATETIME, @CurrenDate DATETIME 

	SELECT @TimeZone = dbo.Aff_f_GetSetting('TimeZone')

	SET @CurrenDate =  DATEADD(HOUR, 4 + @TimeZone, GETDATE())

	IF @IsInclude = 0 
	BEGIN
		SELECT @FromDate = DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0), @ToDate = DATEADD(DAY, -1, DATEADD(MONTH, 1, @FromDate))
	END

	IF @IsRemoved = 1 AND @IsInclude = 1
	BEGIN
		SELECT @FromDate = DATEADD(DAY, 1, CONVERT(DATE, @CurrenDate))
	END

	IF @IsRemoved = 1
	BEGIN
		SET @ToDate = '2079-06-06'
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
				,mr.IsInclude = @IsInclude
				,mr.RemovedBy = @UserId
		FROM MemberRemoval mr
		WHERE mr.CustId = @CustId AND DATEDIFF(MONTH, mr.RemovedDate, @CurrenDate) = 0
	END
	ELSE
	BEGIN	
		INSERT INTO dbo.MemberRemoval (CustId, RemovedDate, FromDate, ToDate, IsInclude, RemovedBy)
		VALUES (@CustId, DATEADD(HOUR, 4 + @TimeZone, @CurrenDate),  @FromDate, @ToDate, @IsInclude, @UserId)
	END

	IF EXISTS (
		SELECT 1 FROM dbo.MemberRemoval mr WITH(NOLOCK) WHERE mr.CustId = @CustId AND DATEDIFF(MONTH, mr.RemovedDate, @CurrenDate) > 0
	)
	BEGIN
		;WITH CTE AS
		(
			SELECT TOP (1) CustId, RemovedDate, mr.ToDate
			FROM MemberRemoval mr WITH(NOLOCK)
			WHERE mr.CustId = @CustId AND DATEDIFF(MONTH, mr.RemovedDate, @CurrenDate) > 0
			ORDER BY mr.RemovedDate DESC
		)
		UPDATE mr WITH(ROWLOCK, UPDLOCK)
			SET mr.ToDate = CASE WHEN mr.ToDate IS NULL THEN NULL ELSE DATEADD(DAY, -1, DATEADD(MONTH, DATEDIFF(MONTH, 0, @CurrenDate), 0)) END
		FROM MemberRemoval mr
			INNER JOIN CTE e ON e.CustId = mr.CustId AND e.RemovedDate = mr.RemovedDate
	END

	UPDATE dbo.MemberInfo WITH(ROWLOCK)
		SET IsRemoved = @IsRemoved
	WHERE CustId = @CustId

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