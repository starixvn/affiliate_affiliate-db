 USE [AffPortal_SPON]
GO
/****** Object:  StoredProcedure [dbo].[EditWidgetMeta]    Script Date: 10/22/2010 11:18:13 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Peter
-- Create date: 10/15/2010
-- Description:	<Description,,>
-- =============================================
ALTER PROCEDURE [dbo].[EditWidgetMeta] 
	-- Add the parameters for the stored procedure here
	@instanceId int,
	@title nvarchar(256),
	@key varchar(MAX),
	@data nvarchar(MAX)	,	
	@editEmbeddableSample bit
	-- data structure
	-- key:		key1,key2,key3
	-- data:	data_of_key1[$$$@@@###]data_of_key2[$$$@@@###]data_of_key3
	 --TODO:
    --UPDATE PageEmbeddableMeta Table
	
	--1. if the widget don't have these keys
			-- create keys and update values
	--2. if the widget have these keys
			-- just update values

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	if @editEmbeddableSample = 0
	begin
		--update title
		if @title <> ''
		begin
			update PageEmbeddables
			set title = @title
			where instanceId = @instanceId
		end
		
		declare @PageEmbeddableMeta table(instanceId int, [key] nvarchar(32), value nvarchar(MAX), orderNo int identity(1,1))
	    
		 BEGIN TRY
						  insert into @PageEmbeddableMeta(instanceId,[key],value)
						  select @instanceId,'',String from [dbo].CLRSplitStringFunction(@data,'[$$$@@@###]',1)
						  update t
						   set [key]=cast(val as varchar(max))
						   from @PageEmbeddableMeta t
							   inner join dbo.strsplit(@key, ',') t1 on t1.rank=t.orderNo
						       
						  update p
						  set p.value=p1.value
						  from  PageEmbeddableMeta p with (rowlock,updlock)
								inner join @PageEmbeddableMeta p1 on p1.instanceId=p.instanceId and p1.[key]=p.[key]
						        
						  insert into  PageEmbeddableMeta(instanceId,[key],value)
						  select instanceId,[key],value
						  from  @PageEmbeddableMeta
						  where  [key] not in (select [key] from PageEmbeddableMeta (nolock) where instanceId=@instanceId )       
						  
						  select convert(bit,1)     
						  
		  END TRY
		  BEGIN CATCH						
				select convert(bit,0)	
		  END CATCH
				   
	end
	else
	--save embeddable sample
	begin
		select convert(bit,1)  
	end
   	
END
