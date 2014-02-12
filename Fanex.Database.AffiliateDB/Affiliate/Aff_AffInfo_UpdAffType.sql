ALTER PROCEDURE [dbo].[Aff_AffInfo_UpdAffType]
	@Updatedby int ,
	@AffID int,
	@AffType tinyint,		
	@IP nvarchar(15)='',	
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 

SET NOCOUNT ON

EXEC dbo.Aff_CheckPermissionOnAff   
 @custid=@Updatedby,  
 @AffId=@AffId,  
 @ErrCode=@ErrCode output,  
 @ErrMsg=@ErrMsg output  
	
If @ErrCode <> 0
	RETURN
	
If(Not Exists (Select 1 from AffInfo (nolock) where AffID=@AffID ))
BEGIN
Select @ErrMsg = case @Language 
				when 'en-US' then 'Error! This affiliate does not exist!'
				when 'zh-CN' then N'錯誤!這個工作夥伴不存在!'
				when 'zh-TW' then N'错误！这个工作伙伴不存在！'
				else N'Error! This affiliate does not exist!'
			end, @ErrCode = 1001
	return
END
update AffInfo with (rowlock,updlock)
Set AffType=@AffType
where AffID=@AffID


declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update AffInfo AffType. AffID= ' + dbo.Aff_ToString(@AffID) 
				+'AffType= ' + dbo.Aff_ToString(@AffType) 
	 

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'AffInfo', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end

   
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbAdminNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbDownlineNet]
GO
GRANT EXECUTE ON [dbo].[Aff_AffInfo_UpdAffType] TO [bodbDownlineNetView]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffInfo_UpdAffType] TO [vnTeam]
GO