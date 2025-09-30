/****** Object:  Stored Procedure dbo.Aff_CustomerCheck12BetPlayerAccountActivated_xpre    Script Date: 12/25/2009 2:01:57 AM ******/  
/****** Object:  Stored Procedure dbo.Aff_CustomerCheck12BetPlayerAccountActivated    Script Date: 11/3/2009 5:46:33 PM ******/  
 Alter PROC  [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated]  
 @AffID int,  
 @language varchar(20) = 'en-US',  
 @12BetPlayerUserName varchar(30)=null OUTPUT,  
 @Result bit=0 OUTPUT,  
 @ErrCode int = 0 OUTPUT,  
 @ErrMsg nvarchar(200) = '' OUTPUT  
AS  
/*  
Created: 20090122@Dung  
Task : Check Affiliate's 12BetPlayer Account is activated or not  
DB: DB052.Affiliate_12BET  
Original:  
  
Revisions:  
 - 20090122@[Reviewer]: [Description of revision]   
  
Param's Explanation:  
• @DepositUserName: return 12bet Player account for this affiliate     
• @Result :    
     =0 : 12bet player account for this affiliate is not activated  
     =1: activated.  
• @ErrCode:  
 = 0: Transaction recorded successfully.  
 > 0: Specific Error.  
   
• @ErrMsg: Error description.  
*/  
SET NOCOUNT ON  
--CONTENT OF SP HERE  
                 
if exists(select 1   
              from bodb02.dbo.customer as c with (NOLOCK)   
                INNER JOIN AffDetail ci (NOLOCK) on '12BET$' + ci.player_username = c.username2  
                   where ci.AffID = @AffID  
         )   
  BEGIN     
     select @Result=1    
 END  
 else  
   BEGIN  
          
      select @Result=0  
      select @12BetPlayerUserName =''  
      select @12BetPlayerUserName =ci.player_username  
              from AffDetail ci (NOLOCK)   
               where ci.AffID = @AffID    
      if @12BetPlayerUserName =''  
        begin  
    Select @ErrMsg = case @language   
        when 'en-US' then 'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
        when 'zh-TW' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
        when 'zh-CN' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'  
        when 'th-TH' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
        when 'vi-VN' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
        when 'id-ID' then N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'   
        when 'es-ES' then N'Este afiliado no dispone de nombre de usuario de jugador de 12BET. Póngase en contacto con el administrador.'   
		when 'ko-KR' then N'죄송합니다. 이 제휴는 12bet플레이어 회원의 아이디를 가지고 있지 않습니다. 관계자에게 문의하세요.'
        else  N'Sorry, this affiliate does not have 12bet player username. Please contact your Administrator.'      
       end,   
   @ErrCode = 30010  
         return  
       end                     
                 
   END

GO
GRANT EXECUTE ON [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated] TO [bodbDownlineNetView]
GO
GRANT EXECUTE ON [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_CustomerCheck12BetPlayerAccountActivated] TO [vnteam]
GO