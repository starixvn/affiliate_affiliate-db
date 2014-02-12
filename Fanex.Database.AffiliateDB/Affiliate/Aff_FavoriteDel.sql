ALTER Procedure [dbo].[Aff_FavoriteDel]  
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
if Not exists(select 1 from AdminFavorite with (nolock) where AdminID = @AdminID and AffID = @AffID)  
begin  
 select @ErrCode = 10021  
 select @ErrMsg = case @Language 
					when 'en-US' then 'This affiliate does not exists.' 
					when 'zh-CN' then N'這個工作夥伴不存在'
					when 'zh-TW' then N'这个工作伙伴不存在'
					else N'This affiliate does not exists.' 
				end
 return  
end  
  
delete AdminFavorite  
where AdminID = @AdminID and AffID = @AffID  
  
IF @@ERROR <> 0  
BEGIN  
 Select @ErrMsg = case @Language 
					when 'en-US' then 'Error! Delete favorite unsuccessfully!' 
					when 'zh-CN' then N'這個工作夥伴不存在'
					when 'zh-TW' then N'这个工作伙伴不存在'
					else N'Error! Delete favorite unsuccessfully!' 
				end, @ErrCode = 10020  
 return  
END  
GO
GRANT EXECUTE ON [dbo].[Aff_FavoriteDel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_FavoriteDel] TO [vnteam]

