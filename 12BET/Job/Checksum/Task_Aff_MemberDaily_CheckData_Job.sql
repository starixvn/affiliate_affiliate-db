/*<info serverAlias="DBAFF12BET-Affiliate_12BET" executers="bodbAdminNet" viewers="" isFunction="0" isNested="0"></info>*/
USE [Affiliate_12BET]
GO

ALTER PROCEDURE [dbo].[Task_Aff_MemberDaily_CheckData_Job]
	@Winlostdate	SMALLDATETIME,
	@AllowCorrect	BIT = 1
AS

/*
	Created by Percy:
	Date: 2017-10-20
	DB: DBAFF12BET.Affiliate_12BET
	Task: Check and correct data after move bet for MemberDaily

	Revisions:
		- 20171020@Percy: Add new SP [RedmineID: #84602]
*/

BEGIN
	SET NOCOUNT ON

	DECLARE @MoveBetSchedule TABLE(RowId TINYINT IDENTITY(1,1), ScheduleId TINYINT, MoveBetDay SMALLDATETIME)

	DECLARE @RowId TINYINT, @VValue TINYINT, @Tomorrow DATETIME, @Today DATETIME
	
	SELECT  @RowId = 1, @Tomorrow = DATEADD(DAY, 1, CAST(GETDATE() AS DATE)), @Today = CAST(GETDATE() AS DATE)

	IF @Winlostdate IS NULL
	BEGIN 
		INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
		EXEC DBTXN.bodb02.dbo.Task_MoveBetsDayByScheduleSel
	END 
	ELSE
	BEGIN 
		INSERT INTO @MoveBetSchedule(ScheduleId, MoveBetDay)
		VALUES (0, @Winlostdate)
	END

	IF NOT EXISTS (SELECT MoveBetDay FROM @MoveBetSchedule)
	BEGIN
		RETURN  ---  move bet does not run
	END

	DECLARE @IsMatch BIT = 0, @Subject VARCHAR(1000) = '', @ErrorMessage VARCHAR(MAX) = ''

	DECLARE @ErrMsgTab TABLE (NoID SMALLINT IDENTITY (1,1), Date VARCHAR(50), ErrMsg VARCHAR(MAX))

	WHILE EXISTS (SELECT 1 FROM @MoveBetSchedule WHERE RowId = @RowId)
	BEGIN
		SELECT @WinlostDate = MoveBetDay FROM @MoveBetSchedule WHERE RowId = @RowId
		SELECT @RowId = @RowId + 1

		EXEC dbo.Task_Aff_MemberDaily_CheckData @Winlostdate = @Winlostdate, @IsMatch = @IsMatch OUTPUT

		IF @IsMatch <> 0
		BEGIN
			IF @AllowCorrect = 1
			BEGIN
				EXEC dbo.Task_Aff_MemberDaily @Winlostdate = @Winlostdate
			END
			
			INSERT INTO @ErrMsgTab (Date, ErrMsg)
			SELECT @Winlostdate, 'Has data mismatch between MemberDaily table and source'
		END
	END

	IF EXISTS (SELECT TOP 1 Date FROM @ErrMsgTab)
	BEGIN
		SELECT @Subject = 'SQL Server Job System:'' Affiliate_12BET: MemberDaily - Check and correct'' completed on \\' + @@SERVERNAME
			
		SELECT @ErrorMessage = '<H3>MemberDaily table has data mismatch</H3>'
								+ '<table border="1"> '
								+ '<tr><th>No.</th><th>Date</th><th>Error Message</th></tr>'
								+ CAST(( SELECT    td = NoID, '',
													td = Date, '',
													td = ErrMsg, ''
										FROM @ErrMsgTab
										FOR XML PATH('tr'), TYPE 
									) AS NVARCHAR(MAX) ) + N'</table>'
			
		EXEC msdb.dbo.sp_send_dbmail
			@recipients		= 'patrick.pham@starixsoft.com',
			@subject		= @subject,
			@body			= @ErrorMessage,
			@body_format	= 'HTML'
	END
END
GO