Alter Procedure [Aff_FavoriteIns]
	@AdminId int,
	@AffId int,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
--DB052.Affiliate_12BET
SET NOCOUNT ON
/*--Favorite is no need to check permission
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@AdminId,@funcname='[Affiliate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
*/
if exists(select 1 from AdminFavorite with (nolock) where AdminID = @AdminID and AffID = @AffID)
begin
	select @ErrCode = 10021
	select @ErrMsg = 'This affiliate has been added before.'
	return
end

insert into AdminFavorite(AdminID, AffID)
values (@AdminID, @AffID)

IF @@ERROR <> 0
BEGIN
	Select @ErrMsg = N'Error! Add favorite unsuccessfully!', @ErrCode = 10020
	return
END

GO
GRANT EXECUTE ON [dbo].[Aff_FavoriteIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_FavoriteIns] TO [vnteam]

