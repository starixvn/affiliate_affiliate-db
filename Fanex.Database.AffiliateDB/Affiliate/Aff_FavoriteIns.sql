ALTER Procedure [dbo].[Aff_FavoriteIns]  
 @AdminId int,  
 @AffId int,  
	@Language varchar(5)= 'en-US', 
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(4000) = '' OUTPUT  
AS  
--DB052.Affiliate_ZZun  
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
 select @ErrMsg = case @Language 
					when 'en-US' then 'This affiliate has been added before.' 
					when 'zh-CN' then N'這個工作夥伴之前已經新增了'
					when 'zh-TW' then N'这个工作伙伴之前已经新增了'
					else N'This affiliate has been added before.' 
				end
 return  
end  
  
insert into AdminFavorite(AdminID, AffID)  
values (@AdminID, @AffID)  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Add favorite unsuccessfully!' 
					when 'zh-CN' then N'錯誤!新增最愛不成功!'
					when 'zh-TW' then N'错误！新增最爱不成功！'
					else N'Error! Add favorite unsuccessfully!' 
				end, @ErrCode = 10020  
 return  
END  

GO
GRANT EXECUTE ON [dbo].[Aff_FavoriteIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_FavoriteIns] TO [vnteam]

