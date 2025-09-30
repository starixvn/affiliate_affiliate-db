ALTER PROCEDURE [dbo].[AffAdmin_CheckMemberExist]
	@MemberName varchar(30),
	@AffName varchar(30),	
	@AffID int = null OUTPUT,
	@AffStatus varchar(20) = null OUTPUT,
	@IsMemberExist bit = 0 OUTPUT,
	@MemberAffID int = null OUTPUT
AS
/*  
	Created: 20090724@Peter
	Task : Check member existing in the system to Affiliate System
	DB: Affiliate DB  
	Original: Affiliate_Athena000

	Revision:
		-Bobby@2010118: - OUT @MemberAffID in case existing of member but removed

*/ 
BEGIN

	SET NOCOUNT ON;

	DECLARE @memberUserName VARCHAR(50)
		, @memberRemoved BIT;

	SELECT @AffID = AffID
		, @AffStatus = [Status] 
	FROM dbo.AffInfo 
	WHERE UserName = @AffName
	
	IF(@AffID IS NULL)
		return
	IF( @AffStatus = 'approved')
	BEGIN 
		IF (EXISTS (SELECT 1 FROM AffInfo WITH(NOLOCK) WHERE UserName = @AffName AND IsClosed =1 ))
			SET @AffStatus = 'closed'
	END
	
	SELECT TOP(1) @memberUserName = mi.UserName
		, @MemberAffID = mi.AffID
		, @memberRemoved = mi.IsRemoved
	FROM dbo.MemberInfo mi WITH (NOLOCK)
	WHERE mi.UserName = @MemberName 

	IF(@memberUserName IS NOT NULL 
		AND @memberRemoved <> 1)
	BEGIN
		SET @IsMemberExist = 1
	END

END

GO
GRANT EXECUTE ON [dbo].[AffAdmin_CheckMemberExist] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[AffAdmin_CheckMemberExist] TO [vnteam]