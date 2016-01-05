ALTER PROCEDURE [dbo].[AffAdmin_ReCheckIn]     
	@On_UserID INT,    
	@IsKickedOut BIT = 0 OUTPUT    
AS    
SET NOCOUNT ON    


/*
	Created: 20151013@Victor
	Task: Re check in
	DB: DBLIC/bodb_Licensee
	
	Revisions:
*/
   
DECLARE @OUTPUT TABLE (IsKickedOut BIT)
DECLARE @_On_UserID INT

SET @_On_UserID = @On_UserID

UPDATE Aff_On_User with (ROWLOCK)
SET Reload_Time = GETDATE() 
OUTPUT DELETED.IsKickedOut INTO @OUTPUT
WHERE On_UserID = @_On_UserID


IF @@ROWCOUNT = 0
	SELECT @IsKickedOut = 1
ELSE IF EXISTS (SELECT 1 FROM @OUTPUT WHERE IsKickedOut = 1)
	SELECT @IsKickedOut = 1
ELSE
	SET @IsKickedOut = 0

GO
GRANT EXECUTE ON [dbo].[AffAdmin_ReCheckIn] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[AffAdmin_ReCheckIn] TO [bodbLicenseeNet] AS [dbo]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_ReCheckIn] TO [vnteam] AS [dbo]