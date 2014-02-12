USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_LanguageSelByID]    Script Date: 02/08/2013 14:45:38 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[Aff_AffTypeSelByID]	
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
From AffType (nolock)
where TypeID=@ID
