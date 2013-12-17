 USE [Affiliate_12BET]
GO
/****** Object:  StoredProcedure [dbo].[DBA_GetPT]    Script Date: 10/31/2009 07:45:19 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[DBA_GetPT]
	@InputUser varchar(30),
	@Bettype tinyint = 1,
	@Sporttype tinyint = 1,
	@islive bit =0

AS
/*
  DB052.AFFILIATE_12BET
*/
SET NOCOUNT ON
EXEC bodb02.dbo.dba_getpt 
@InputUser = @InputUser,
@Bettype = @Bettype,
@Sporttype = @Sporttype,
@islive = @islive

GRANT EXECUTE ON [dbo].[DBA_GetPT] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[DBA_GetPT] TO [vnteam]



