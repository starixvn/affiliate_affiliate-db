ALTER PROCEDURE [dbo].[Aff_DomainControlIns]
	@AffDomainID int,
	@12BetDomainID int,
	@MarketID nvarchar(10),
	@Creator int,
	@Status bit = 1,	
	@UserID int,	
	@IP nvarchar(15)='',
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
If Exists(select 1 from AffDomainControl nolock where AffDomainID = @AffDomainID and [12BetDomainID] = @12BetDomainID and MarketID = @MarketID)
Begin
	select @ErrCode = 1001,
			@ErrMsg = 'This domain setting has been existed!'
	return
End

declare @CreatedDate datetime
select @CreatedDate=Current_Timestamp

BEGIN TRANSACTION
INSERT INTO [AffDomainControl]
   (	
        [AffDomainID]
	   ,[12BetDomainID]
       ,[MarketID]
       ,[CreateDate]
       ,[ModifyDate]
       ,[Creator]
       ,[Status]
	)
	VALUES
	(	        
		@AffDomainID,
		@12BetDomainID,
        @MarketID,
		@CreatedDate,
		@CreatedDate,
        @Creator,
		@Status
	)
IF @@ERROR <> 0
BEGIN
	ROLLBACK TRANSACTION
	Select @ErrMsg = 	N'Error occurs.Insert data unsuccessfully.', @ErrCode = 1002
	return
END

COMMIT TRANSACTION

--Write log
declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Create AffDomainID:' + dbo.Aff_ToString(@AffDomainID)                     
                    + ' 12BetDomainID:' + dbo.Aff_ToString(@12BetDomainID)                    
					+ ' MarketID:' + dbo.Aff_ToString(@MarketID)                    

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