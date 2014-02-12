CREATE PROCEDURE [dbo].[Aff_TaskLogUpdStatus]
	@LogID int,
	@Status varchar(50) 
AS
BEGIN
	update TaskLog with (rowlock,updlock)
	set Status=@Status, CompletedDate=CURRENT_TIMESTAMP 
	where LogID=@LogID

	if lower(@Status)='completed'
	begin
	    update TaskManager with (rowlock,updlock)
		set  LastRun=CURRENT_TIMESTAMP
		where TaskID= (select top(1) TaskID from TaskLog (nolock) where LogID=@LogID)
    end
END

GO

GRANT EXECUTE ON [dbo].[Aff_TaskLogUpdStatus] TO [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TaskLogUpdStatus] TO [vnteam]