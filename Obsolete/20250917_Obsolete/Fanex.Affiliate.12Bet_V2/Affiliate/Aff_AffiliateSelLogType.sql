 USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[Aff_AffiliateSelLogType]    Script Date: 05/15/2010 17:02:52 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_AffiliateSelLogType]
	
AS
/*
	Created: 20100423@Jacob
	Task : Get all log type
	DB: DB052.Affiliate_12BET
	Revisions:
		- 20100423@Jacob initialize
		
	Param's Explanation:

*/
SET NOCOUNT ON;
	
SELECT [TypeID]
	  ,[TypeName]
	  ,[Description]
  FROM [Affiliate_12BET].[dbo].[LogType]

GO
GRANT EXECUTE ON [dbo].[Aff_AffiliateSelLogType] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_AffiliateSelLogType] TO [vnteam]
  
