 
USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_MemberSel]    Script Date: 05/15/2010 17:29:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Aff_MemberSel]
	@IBCCustID INT
AS
/*
	Created: 20090701@Jacob	
	DB: DB052.Affiliate_12Bet

*/
SET NOCOUNT ON;
SELECT [IBCCustID]
	  ,[AffID]
	  ,[UserName]
	  ,[IBCUserName]
	  ,[CreatedDate]
	  ,[RegisteredDate]
	  ,[IsRemoved]
	  ,[DepositCustID]
	  ,[FirstName]
	  ,[LastName]
	  ,[Currency]
	  ,[Email]
	  ,[Recommend]
FROM [Affiliate_12BET].[dbo].[MemberInfo]
WHERE [IBCCustID]= @IBCCustID

GO
GRANT EXECUTE ON [dbo].[Aff_MemberSel] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_MemberSel] TO [vnteam]
  

