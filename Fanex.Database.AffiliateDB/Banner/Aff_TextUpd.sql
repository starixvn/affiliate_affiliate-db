USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_TextUpd]    Script Date: 01/30/2013 10:08:35 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
/****** Object:  Stored Procedure dbo.Aff_TextUpd_xpre    Script Date: 4/3/2012 3:07:15 AM ******/
/****** Object:  Stored Procedure dbo.Aff_TextUpd    Script Date: 2/24/2012 10:17:35 AM ******/

CREATE PROCEDURE [dbo].[Aff_TextUpd]
	@BannerID int ,
	@Message nvarchar(max),
	@Category varchar(50)=null,
	@Language varchar(50)=null,
	@Currency varchar(5)=null,
	@UserID int,	
	@IP nvarchar(15)='',
	@LanguageSite varchar(5)= 'en-US',
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,@funcname='[Media]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------

UPDATE Banners with(rowlock,updlock)
SET 	
	LastUpdate = getdate(),
	UpdatedBy=@UserID,
	[Message] = coalesce(@Message,Category),
	Category=coalesce(@Category,Category),
	[Language]=coalesce(@Language,[Language]),
	Currency=coalesce(@Currency,Currency)
WHERE BannerID=@BannerID
IF @@Error <> 0 
BEGIN
	Select @ErrMsg = case @LanguageSite 
							when 'en-US' then 'Error occurs.Updte unsuccessfully.' 
							when 'zh-CN' then N'錯誤發生.更新不成功!'
							when 'zh-TW' then N'错误发生。更新不成功！'
							else N'Error occurs.Updte unsuccessfully.' 
						end, @Errcode=1001
	return
END 
	Select @Errcode=0

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Update bannerID:' + dbo.Aff_ToString(@BannerID) 
                  +  ' Message:'  + @Message
                  +  ' Category:' + dbo.Aff_ToString(@Category)
                  +  ' Language:' + dbo.Aff_ToString(@Language)
                  +  ' Currency:' + dbo.Aff_ToString(@Currency)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'Banner', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP