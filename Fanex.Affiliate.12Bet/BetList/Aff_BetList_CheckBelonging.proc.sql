ALTER PROCEDURE [dbo].[Aff_BetList_CheckBelonging]    
	@AdminName 			VARCHAR(30)	= NULL
	,@AffId 			INT = 0
	,@MemberName 		VARCHAR(30)
	,@SysName			VARCHAR(30) = '12Bet'
	,@BelongLevel1		BIT = 0 OUTPUT
	,@BelongLevel2		BIT = 0	OUTPUT
AS    
/*
Created:20150312@Bobby.Nguyen
Task: Aff Betlist
DB: DBEXT/Affiliate_12Bet
Orgiginal: 

Revisions:    
	- 20150312@Bobby.Nguyen: Initial SP
	- 20150821@Bobby.Nguyen: Cover the username and username2
*/     
BEGIN    
	SET NOCOUNT ON;
	DECLARE @username 	VARCHAR(30)
		, @username2	VARCHAR(50)
	
	DECLARE @tblMember TABLE(
		MemberName	VARCHAR(30)
		,Currency	SMALLINT
	);
	
	-- reset value 
	SELECT @BelongLevel1 	= 0
		, @BelongLevel2 	= 0
		, @username			= SUBSTRING(@MemberName,CHARINDEX ('$',@MemberName,1)+1,LEN(@MemberName))
		, @username2		= '12Bet$' + @username
		
	-- gather member info for both (Athena & 12Bet)
	INSERT INTO @tblMember(MemberName, Currency)
	SELECT  
		a.UserName
		, a.Currency
	FROM dbo.MemberInfo a WITH (NOLOCK)
	WHERE a.AffId 		= @AffId
		AND (a.UserName = @username OR a.UserName = @username2)
		
	IF EXISTS(SELECT TOP 1 1 FROM @tblMember a)
	BEGIN 
		SET @BelongLevel2 = 1
	END
	
	RETURN;
END  
GO
GRANT EXECUTE ON [dbo].[Aff_BetList_CheckBelonging] TO [bodbAdminNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_CheckBelonging] TO [bodbDownlineNet] AS [dbo]
GO

GRANT EXECUTE ON [dbo].[Aff_BetList_CheckBelonging] TO [bodbDownlineNetView] AS [dbo]
GO
