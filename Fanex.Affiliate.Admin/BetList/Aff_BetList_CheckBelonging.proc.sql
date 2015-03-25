USE [Affiliate_Athena000]
GO
/****** Object:  StoredProcedure [dbo].[Aff_BetList_CheckBelonging]    Script Date: 3/13/2015 9:48:29 AM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_BetList_CheckBelonging]    
	@AdminName 			VARCHAR(30) = NULL
	,@AffId 			INT = 0
	,@MemberName 		VARCHAR(30)
	,@SysName			VARCHAR(30) = 'Athena'
	,@BelongLevel1		BIT = 0 OUTPUT
	,@BelongLevel2		BIT = 0	OUTPUT
AS    
/*
Created:20150312@Bobby.Nguyen
Task: Aff Betlist
DB: DBAFF/Affiliate_Athena000
Orgiginal: 

Revisions:    
	- 20150312@Bobby.Nguyen: Initial SP
*/     
BEGIN    
	SET NOCOUNT ON;
	
	DECLARE @IsNoComm	BIT
	
	DECLARE @tblAdmin TABLE(
		AdminName	VARCHAR(30)
		,Currency	SMALLINT
	);
	
	DECLARE @tblAff TABLE(
		AffName		VARCHAR(30)
		,Currency	SMALLINT
	);
	
	DECLARE @tblMember TABLE(
		MemberName	VARCHAR(30)
		,Currency	SMALLINT
	);
	
	-- reset value 
	SELECT @BelongLevel1 	= 0
		, @BelongLevel2 	= 0
	
	-- gather admin info
	INSERT INTO @tblAdmin(AdminName, Currency)
	SELECT a.UserName
		, p.AttributeID
	FROM dbo.AffGroupPermissionDetail p WITH(NOLOCK)
		INNER JOIN dbo.AdminUser a WITH (NOLOCK)
		ON p.ObjectId = a.CustId
	WHERE a.Username = @AdminName
	
	-- gather affiliate info
	INSERT INTO @tblAff(AffName, Currency)
	SELECT a.UserName
		, a.Currency
	FROM dbo.AffInfo a WITH (NOLOCK)
		INNER JOIN dbo.CommGroup g WITH (NOLOCK)
		ON a.GroupId = g.GroupId
	WHERE a.AffId = @AffId
	
	-- gather member info for both (Athena & 12Bet)

	INSERT INTO @tblMember(MemberName, Currency)
	SELECT a.UserName
		, a.Currency
	FROM dbo.MemberInfo a WITH (NOLOCK)
	WHERE a.UserName = @MemberName
		AND a.AffId = @AffId
	
	IF EXISTS(SELECT TOP 1 1
			FROM @tblAdmin a
				INNER JOIN @tblAff f
				ON a.Currency = f.Currency
	)
	BEGIN 
		SET @BelongLevel1 = 1
	END
	
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