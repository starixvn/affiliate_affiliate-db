ALTER PROCEDURE [dbo].[Aff_DomainControlIns]
	@AffDomainID int,
	@MemberDomainID int,
	@CountryID nvarchar(10),
	@Creator int,
	@Status bit = 1,	
	@UserID int,	
	@IP nvarchar(15)='',
	@Language varchar(5)= 'en-US', 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
/*
Created: 20121115@Johnny.Trinh
Task : Add a new AffDomainControl
DB: DB052.Affiliate_12BET
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission]
	@custid=@UserID,@funcname='[Domain]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN
-----------------------------------------------
If Exists(select 1 from AffDomainControl nolock where AffDomainID = @AffDomainID and [MemberDomainID] = @MemberDomainID and CountryID = @CountryID)
Begin
	select @ErrCode = 1001,
			@ErrMsg = case @Language 
					when 'en-US' then 'This domain setting has been existed!' 
					when 'zh-CN' then N'??????????!'
					when 'zh-TW' then N'???????????'
					else N'This domain setting has been existed!' 
				end
	return
End

declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO [AffDomainControl]
   (	
        [AffDomainID]
	   ,[MemberDomainID]
       ,[CountryID]
       ,[CreateDate]
       ,[ModifyDate]
       ,[Creator]
       ,[Status]
	)
	VALUES
	(	        
		@AffDomainID,
		@MemberDomainID,
        @CountryID,
		@CreatedDate,
		@CreatedDate,
        @Creator,
		@Status
	)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = case @Language 
						when 'en-US' then 'Error occurs.Insert unsuccessfully.'
						when 'zh-CN' then N'????.?????'
						when 'zh-TW' then N'??????????'
						else N'Error occurs.Insert unsuccessfully.!'
					end, @ErrCode = 1002
	return
END

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' MemberDomainID:' + dbo.Aff_ToString(@MemberDomainID)                    
					+ ' CountryID:' + dbo.Aff_ToString(@CountryID)                    

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @UserID,
	@Typename = 'AffDomainControl', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP



GO
GRANT EXECUTE ON [dbo].[Aff_DomainControlIns] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DomainControlIns] TO [vnteam]