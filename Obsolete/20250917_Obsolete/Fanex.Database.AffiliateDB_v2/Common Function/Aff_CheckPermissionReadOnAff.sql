ALTER PROCEDURE [dbo].[Aff_CheckPermissionReadOnAff]  
 @CustId int,  
 @Username varchar(50) = '',  
 @AffId int = 0,  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*  
 Created: 20090730@Peter  
 Task : Select affiliate info for left panel  
 DB: DB052.Affiliate_ZZun  
  
 Revisions:  
   .20090823@Peter : Rewrite the sp for new DB DB052.Affiliate_ZZun  
                     Remove the theory of pending commission and CurrCommEarning     
                     Get PreferredPayment to check approve   
 Param's Explanation:  
 • @Username : Affiliate username  
*/  
SET NOCOUNT ON  
  
Declare @AffType tinyint  
  
if @AffId != 0  
Begin  
 select @AffType = AffType  
 From AffInfo with (nolock)  
 where AffId = @AffId  
End  
else  
Begin  
 select @AffType = AffType  
 From AffInfo with (nolock)  
 where Username = @Username  
End  
  
if @AffType is null  
Begin  
 SELECT @ErrMsg = case @Language 
						when 'en-US' then 'You are not authorized on this function'
						when 'zh-TW' then N'您尚未被授權這個功能'
						when 'zh-CN' then N'您尚未被授权这个功能'
						else N'You are not authorized on this function'
						end, @ErrCode = 500  
 RETURN   
End  
  
If @AffType = 2  
Begin  
 EXEC DB03.bodb02.dbo.Aff_Con_CheckPermissionRead   
  @custid=@CustId,  
  @funcname='[MediaAffiliate]',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output  
   
End  
Else  
Begin  
 EXEC DB03.bodb02.dbo.Aff_Con_CheckPermissionRead   
  @custid=@CustId,@funcname='[Affiliate]',  
  @ErrCode=@ErrCode output,  
  @ErrMsg=@ErrMsg output   
End  

GO
GRANT EXECUTE ON [dbo].[Aff_CheckPermissionReadOnAff] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CheckPermissionReadOnAff] TO [VNTeam]
