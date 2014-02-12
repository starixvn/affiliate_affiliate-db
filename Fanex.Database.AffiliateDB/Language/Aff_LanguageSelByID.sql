USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSelByID]    Script Date: 01/22/2013 16:55:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_LanguageSelByID]	
	@ID VARCHAR(8)
AS
/*
Created: 20110221@Peter
Task : Get 1 Settings From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select *
From Language (nolock)
where LanguageID=@ID
