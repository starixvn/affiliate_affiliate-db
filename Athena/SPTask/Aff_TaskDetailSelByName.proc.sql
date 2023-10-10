CREATE PROCEDURE [dbo].[Aff_TaskDetailSelByName]
	@TaskName varchar(100)
	
AS
BEGIN
	select top(1) * from TaskManager(nolock) where TaskName=@TaskName
END
	

GO

GRANT EXECUTE ON [dbo].[Aff_TaskDetailSelByName] TO [bodbAdminNet]

GO

GRANT VIEW DEFINITION ON [dbo].[Aff_TaskDetailSelByName] TO [vnteam]