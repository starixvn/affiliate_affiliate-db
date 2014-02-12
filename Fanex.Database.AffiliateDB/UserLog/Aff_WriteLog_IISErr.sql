Alter Procedure [Aff_WriteLog_IISErr]
	@LoggedDate smalldatetime,
	@Page varchar(50) = '',
	@Function varchar(100) = '',
	@ErrMessage nvarchar(4000) = '',
	@ErrCode int = 0 Output,
	@ErrMsg nvarchar(400) = '' Output
AS

SET NOCOUNT ON

Insert into UserLog_IISErr([LoggedDate], [Page], [Function], [ErrMessage])
Values(@LoggedDate, @Page, @Function, @ErrMessage)

If @@Error <> 0
Begin
	select @ErrCode = 10050, @ErrMsg = 'Error when inserting log.'
End

GO
GRANT EXECUTE ON [dbo].[Aff_WriteLog_IISErr] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_WriteLog_IISErr] TO [VnTeam]