 ALTER PROCEDURE [dbo].[Aff_AffiliateUpdStatus]
	@AffID int,
	@UserID int,
	@Status varchar(30),	
	@Password varchar(40)= NULL,  
	@GroupID int=NULL, 
	@IP varchar(20), 
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(200) = '' OUTPUT
AS
/*Created: 20090825@Peter
Task : Update affiliate status from disapproved->pending , disapproved-> approved,pending-->disapproved,pending-->approved
DB: DB052.Affiliate_12BET
Original : [Aff_CustomerUpdStatus]
Revisions:

Param's Explanation:
• @AffID : Affiliate ID
• @userid : User update
• @Status : Update status
• @Password: Make a password for affiliate when approving
• @GroupID: when approving user need to assign a new grooup
			groupid<1000 : a common group
			groupid>1000: a private group for this affiliate must be created before. This sp will be called from sp Aff_CommGroupIns
			   
• @ErrCode
• @ErrMsg
*/
SET NOCOUNT ON
--Check permission-----------------------------
EXEC [dbo].[Aff_Con_CheckPermission] 
	@custid=@UserID,@funcname='[Affiliate]',
	@System = 'AFFILIATE',
	@ErrCode=@ErrCode output,
	@ErrMsg=@ErrMsg output
	
If @ErrCode <> 0
	RETURN

if(not exists(select 1 from AffInfo with (nolock) where affid=@affid))
begin
	SELECT @ErrMsg = 'Invalid Affiliate!', @ErrCode = 1005
			return
end
-----------------------------------------------
if(@Status not in ('approved','disapproved','pending'))
begin 
	SELECT @ErrMsg = 'Invalid status!', @ErrCode = 1006
		return
end


if @Status= 'approved' --from disapproved,pending-->approved
	Begin
		IF Exists(Select 1
				  From AffInfo ai with(nolock) 
				  where ai.email=(select email from AffInfo with (nolock) where affid=@affid)
						and ai.affid <> @affid and lower(ai.Status)='approved')
		BEGIN
			SELECT @ErrMsg = 'Email Address has been used. Please choose another one!', @ErrCode = 1007
			return
		END	
	   if(not exists(select 1 from CommGroup with (nolock) where groupid=@groupid and IsDeleted=0))
		BEGIN
			SELECT @ErrMsg = 'Invalid group!', @ErrCode = 1008
			return
		END		
End
BEGIN TRANSACTION 
UPDATE AffInfo with(rowlock,updlock) 
SET [Password] = isnull(@Password,[Password]),
	[Status]=@Status,
	GroupID=isnull(@GroupID,GroupID),
	ApprovedDate=(case when @Status in ('approved','disapproved') then current_timestamp else null end)		
WHERE affid = @affid
IF @@Error <> 0 
begin
	SELECT @ErrMsg = 'There was an error when updating data.', @ErrCode = 1008
	ROLLBACK TRANSACTION
	return
end


Declare @CasinoId int
select @CasinoId = dbo.Aff_GetSportID('Casino')
--Update CasinoJoinedDate if 
if(Exists(select 1 from GroupSetting nolock where GroupId = @GroupID and SportType = @CasinoId))
Begin
	Update AffInfo with(rowlock,updlock) 
	SET CasinoJoinedDate = convert(varchar(10), current_timestamp, 120)
	WHERE affid = @affid and CasinoJoinedDate is null
	
	IF @@Error <> 0 
	begin
		SELECT @ErrMsg = 'There was an error when updating data.', @ErrCode = 1008
		ROLLBACK TRANSACTION
		return
	end
End


COMMIT TRANSACTION

--Write the log 
DECLARE @LogData nvarchar(4000),@SPName varchar(100)

SELECT @LogData = 'Update Affiliate''s Status. '
				  + 'Status=' + dbo.Aff_ToString(@Status)
				  + '. Password=' + dbo.Aff_ToString(@Password)
				  + '. GroupID=' + dbo.Aff_ToString(@GroupID)  
select @SPName=OBJECT_NAME(@@ProcID)

EXEC [dbo].[Aff_WriteLog]
	@Creator=@UserId,	
	@AffID=@AffID,
	@Typename= 'UserInfo',	
	@SPName=@SPName ,
	@IP =@IP,
	@Details=@LogData		

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateUpdStatus] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateUpdStatus] TO [VnTeam]