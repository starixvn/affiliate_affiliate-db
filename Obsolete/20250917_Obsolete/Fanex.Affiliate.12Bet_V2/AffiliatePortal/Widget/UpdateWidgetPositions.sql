 USE [AffPortal_12BET]
GO
/****** Object:  StoredProcedure [dbo].[UpdateWidgetPositions]    Script Date: 10/23/2010 10:22:22 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/13/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[UpdateWidgetPositions]
	-- Add the parameters for the stored procedure here
	@pageId uniqueidentifier,
	@bucketList varchar(1024),
	@embeddableList varchar(1024),	
	@ErrMsg nvarchar(4000) ='' OUTPUT
	
	/*
		@bucketList: CONTENT,RIGHT
		@embeddableList: 5,7,3;8,4,2,10
		
	*/
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON
	--check pageid from PageEmbeddablesTemp
	if(not exists (select 1 from PageEmbeddables with (nolock) where pageid=@pageID))
	 begin
		select @ErrMsg='Invalid page!'
	 end 
	 declare @PageEmbeddables table (bucket nvarchar(64),instanceId int, orderNo smallint)
	 declare @rank int,@bucketName nvarchar(64),@embeddableArray varchar(1024)
	 select @rank=min(rank) from dbo.strsplit(@bucketList, ',')	  
	 
	 if @rank is not null
	begin
			while @rank is not null
				begin
				   BEGIN TRY
					   --Voi moi Bucket
					   
					   select @bucketName=cast(val as nvarchar(64)) from dbo.strsplit(@bucketList, ',') where rank=@rank
					   select @embeddableArray=cast(val as varchar(1024)) from dbo.strsplit(@embeddableList, ';') where rank=@rank
					   Insert into @PageEmbeddables(bucket,instanceId,orderNo)
					    select @bucketName,cast(val as int),rank
						from dbo.strsplit(@embeddableArray, ',')	  
					    select @rank=min(rank) from dbo.strsplit(@bucketList, ',') where rank>@rank  
					  
				   END TRY
				   BEGIN CATCH						
						Select @ErrMsg = ERROR_MESSAGE()
						return	
				   END CATCH
				 
				end --end outer while
	end --end if
else ---Invalid Setting Data
  begin	
	Select @ErrMsg = N'Error! Invalid Input Data !'
	return	
  end 	
 
  update a
  set a.bucket=b.Bucket,
      a.orderNo=b.orderNo
  from PageEmbeddables a with (rowlock,updlock)
      inner join  @PageEmbeddables b on b.instanceId=a.instanceId      
 
 
    
  END

