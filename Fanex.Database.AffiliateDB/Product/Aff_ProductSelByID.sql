USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_ProductSelByID]    Script Date: 01/23/2013 13:43:59 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_ProductSelByID]	
	@ID tinyint
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
From Product (nolock)
where ProductID=@ID
