ALTER PROCEDURE [dbo].[AffAdmin_AffiliateUpdStatus] 
	@LicenseeID INT
	,@AffID INT
	,@UserID INT
	,@Status VARCHAR(30)
	,@Password VARCHAR(40) = NULL
	,@GroupID INT = NULL
	,@IP VARCHAR(20)
	,@Language VARCHAR(5) = 'en-US'
	,@ErrCode INT = 0 OUTPUT
AS
/*Created: 20090825@Peter  
Task : Update affiliate status from disapproved->pending , disapproved-> approved,pending-->disapproved,pending-->approved  
DB: DB052.Affiliate_ZZun  
Original : [Aff_CustomerUpdStatus]  
Revisions:  
  -Long@20130911: do not check email existance in case of Kiosk
  -20140127@Bobby: inogre currency checking when assign NoCommission group
  -20140325@Bobby: check/remove unique email
  -20151119@Victor: Implement SSO from Internal Admin to Affiliate Admin site

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
BEGIN
	SET NOCOUNT ON;

	--Check permission-----------------------------  
				EXEC [dbo].[Aff_Con_CheckPermission] @LicenseeID = @LicenseeID
		,@custid = @UserID
		,@funcname = '[Affiliate]'
		,@System = 'AFFILIATE'
		,@ErrCode = @ErrCode OUTPUT

	IF @ErrCode <> 0 RETURN

	DECLARE @Email NVARCHAR(50)
		,@AffUserName NVARCHAR(50)

	SELECT @AffUserName = UserName
		, @Email = Email
	FROM AffInfo WITH (NOLOCK)
	WHERE affid = @affid

	IF (@AffUserName IS NULL)
	BEGIN
		SELECT @ErrCode = 1006

		RETURN
	END

	-----------------------------------------------  
	IF (@Status NOT IN ('approved', 'disapproved', 'pending'))
	BEGIN
		SELECT @ErrCode = 1007

		RETURN
	END

	IF @Status = 'approved' --from disapproved,pending-->approved  
	BEGIN
		IF EXISTS (
				SELECT 1
				FROM AffInfo ai WITH (NOLOCK)
				WHERE ai.email = (
						SELECT email
						FROM AffInfo WITH (NOLOCK)
						WHERE affid = @affid
						) AND ai.affid <> @affid AND lower(ai.STATUS) = 'approved'
				)
		BEGIN
			SELECT @ErrCode = 15

			RETURN
		END

		IF (
				NOT EXISTS (
					SELECT 1
					FROM CommGroup WITH (NOLOCK)
					WHERE groupid = @groupid AND IsDeleted = 0
					)
				)
		BEGIN
			SELECT @ErrCode = 1008

			RETURN
		END

		--Check Currency is valid  
		DECLARE @Currency VARCHAR(5)

		SELECT @Currency = currency
		FROM AffINfo(NOLOCK)
		WHERE AffID = @AffID

		IF (
				NOT EXISTS (
					SELECT 1
					FROM CommGroup WITH (NOLOCK)
					WHERE groupid = @groupid 
						AND (@groupid=102 OR Currency = @Currency) --inogre currency checking when assign NoCommission group
					)
				)
		BEGIN
			SELECT @ErrCode = 1009

			RETURN
		END
	END

	DECLARE @GroupName NVARCHAR(100)

	SELECT @GroupName = GroupName
	FROM commgroup NOLOCK
	WHERE GroupId = @GroupID

	BEGIN TRANSACTION

	UPDATE AffInfo WITH (ROWLOCK, UPDLOCK)
	SET [Password] = isnull(@Password, [Password])
		,[Status] = @Status
		,GroupID = isnull(@GroupID, GroupID)
		,ApprovedDate = (CASE 
			WHEN @Status IN ('approved', 'disapproved') THEN current_timestamp
			ELSE NULL END
			)
		,AffType = (CASE 
			WHEN @GroupName = 'Media' THEN 2
			ELSE AffType END
			)
	WHERE affid = @affid

	IF @@Error <> 0
	BEGIN
		SELECT @ErrCode = 1010

		ROLLBACK TRANSACTION

		RETURN
	END

	COMMIT TRANSACTION

	--Write the log   
	DECLARE @LogData NVARCHAR(4000)
		,@SPName VARCHAR(100)

	SELECT @LogData = 'Update Affiliate''s Status. ' + 'Status=' + dbo.Aff_ToString(@Status) + '. Password=' + dbo.Aff_ToString(@Password) + '. GroupID=' + dbo.Aff_ToString(@GroupID)

	SELECT @SPName = OBJECT_NAME(@@ProcID)

	EXEC [dbo].[Aff_WriteLog] @Creator = @UserId
		,@AffID = @AffID
		,@Typename = 'UserInfo'
		,@SPName = @SPName
		,@IP = @IP
		,@Details = @LogData
END
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdStatus] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_AffiliateUpdStatus] TO [bodbDownlineNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_AffiliateUpdStatus] TO [vnteam] AS [dbo]