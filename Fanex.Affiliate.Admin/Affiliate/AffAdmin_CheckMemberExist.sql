-- =============================================
-- Script Template
-- =============================================
ALTER Procedure [dbo].[AffAdmin_CheckMemberExist]
	@MemberName varchar(30),
	@AffName varchar(30),	
	@AffID int = null OUTPUT,
	@AffStatus varchar(20) = null OUTPUT,
	@IsMemberExist bit = 0 OUTPUT
	
AS
begin

SET NOCOUNT ON

	select @AffID = AffID,@AffStatus = [Status] from AffInfo where UserName = @AffName
	
	if(@AffID = null)
		return
	if @AffStatus = 'approved'
	begin 
		if (exists (Select 1 from AffInfo(nolock) where UserName=@AffName and IsClosed =1 ))
			set @AffStatus = 'closed'
	end
	
	select @IsMemberExist = count(1) from MemberInfo where UserName = @MemberName and IsRemoved != 1

end

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CheckMemberExist] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CheckMemberExist] TO [vnteam]