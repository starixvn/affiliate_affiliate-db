USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_CountrySelByID]    Script Date: 01/22/2013 16:55:56 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_CountrySelByID]	
	@ID VARCHAR(6)
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
From Country (nolock)
where CountryID=@ID
