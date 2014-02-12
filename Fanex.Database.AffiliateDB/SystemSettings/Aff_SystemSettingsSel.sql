USE [Affiliate_ZZun]
GO
/****** Object:  StoredProcedure [dbo].[Aff_SystemSettingsSel]    Script Date: 03/29/2013 10:19:32 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
ALTER PROCEDURE [dbo].[Aff_SystemSettingsSel]
	@ID int = 0,
	@Type varchar(50)=NULL,
	@Name varchar(50) =NULL,
	@Environment varchar(50) = NULL,
	@Value nvarchar(256)=NULL
AS
/*
Created: 20130327@Joseph
Task : Get All Settings From System
DB: DB052.Affiliate_ZZun
Original:

Param's Explanation (filtered by):

*/
SET NOCOUNT ON

Select @Name='%' + isnull(rtrim(ltrim(@Name)),'') + '%'
Select @Value='%' + isnull(rtrim(ltrim(@Value)),'') + '%'

SELECT [SID], [SName], [SValue],[Type],[Description]
	FROM SystemSettings S WITH (NOLOCK)		
	where (@ID IS NULL OR @ID = 0 OR SID = @ID) AND SName like @Name and Type =coalesce(@Type,Type) and SValue like @Value 

