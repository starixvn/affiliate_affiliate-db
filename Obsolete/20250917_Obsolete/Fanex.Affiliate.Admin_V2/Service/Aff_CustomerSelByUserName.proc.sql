USE [bodb02]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CustomerSelByUserName]    Script Date: 1/17/2014 12:49:58 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROC [dbo].[Aff_CustomerSelByUserName] 
	@UserName varchar(50)
AS
/*
Created: 20140108@Bobby.Nguyen
Task : get customer info by username
DB: DBEXT/bodb02
Original: Aff site

Revisions:	
	
Param's Explanation:
	@username: username want to get all related info 
*/	
BEGIN

	SET NOCOUNT ON;

	IF(ISNULL(@UserName, '') <> '')
	BEGIN
		SELECT TOP(1) c.UserName
			, c.username2
			, c.firstname
			, c.lastname
			, c.email
			, c.creatdate as CreatedDate
		FROM dbo.Customer c WITH(NOLOCK)
		WHERE c.username = @UserName
	END
END
GO 

GRANT EXECUTE ON [dbo].[Aff_CustomerSelByUserName] TO [bodbAdminNet] AS [dbo]