ALTER PROCEDURE [dbo].[Aff_TaskLogIns]
	@TaskID smallint,
	@RunDate datetime,
	@Status varchar(50),
	@LogID int OUTPUT
AS

BEGIN
	
	insert into TaskLog(TaskID,RunDate,Status,CompletedDate)
	values(@TaskID,@RunDate,@Status,GETDATE())
	select @LogID=SCOPE_IDENTITY()
	if lower(@Status)='completed'
	begin
	    update TaskManager with (rowlock,updlock)
		set  LastRun=GETDATE()
		where TaskID=@TaskID
    end
END



GO

GRANT EXECUTE ON [dbo].[Aff_TaskLogIns] TO [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TaskLogIns] TO [vnteam]