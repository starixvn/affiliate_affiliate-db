 
-------------------------------------------------------------------------------------------------------------

ALTER PROCEDURE Aff_ResourcesTranslationInsOrUpdate
	@Updatedby int ,
	@Key varchar(50),
	@Value nvarchar(max),
	@Type varchar(50),
	@LanguageCode varchar(8),
	@Description nvarchar(100)= '',
	@IP nvarchar(15)='',
	@ID uniqueidentifier='00000000-0000-0000-0000-000000000000' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
AS
BEGIN
	SET NOCOUNT ON
	
	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[Resources]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
		
	IF @ErrCode <> 0
		RETURN
	
	DECLARE @SPName varchar(50), @Detail nvarchar(4000)
	SELECT @SPName = OBJECT_NAME(@@ProcID)
	DECLARE @TempID uniqueidentifier
 
	SELECT @TempID=ResourceID FROM RefResources (NOLOCK) 
							WHERE RefID=@Type 
							AND [LanguageCode]=@LanguageCode 
							AND [ResourceKey]=@Key
	
	IF(@TempID IS NOT NULL)
		BEGIN
			UPDATE [dbo].[RefResources]
			SET [ResourceValue] = @Value
			WHERE [ResourceID] = @TempID

			SELECT @Detail = 'Update ResourceID:' + CAST(@TempID AS VARCHAR(40)) 
					+  '\n RefID:'			+ dbo.Aff_ToString(@Type)
					+  '\n LanguageCode:'	+ dbo.Aff_ToString(@LanguageCode)
					+  '\n ResourceKey:'	+ dbo.Aff_ToString(@Key)
					+  '\n ResourceValue:'	+ isnull(@Value,'')
					+  '\n Description:'	+ dbo.Aff_ToString(@Description)
		END
	ELSE
		BEGIN
				SELECT @ID = newid()
					
				INSERT INTO [dbo].[RefResources]
					   ([ResourceID],
						[RefID],
						[LanguageCode],
						[ResourceKey],
						[ResourceValue],
						[Description] )
				VALUES (@ID,@Type,@LanguageCode,@Key,@Value,@Description)	
				
				SELECT @Detail = 'Add new Resource. ID=' + dbo.Aff_ToString(@ID) + '.Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type) + '.Language=' + dbo.Aff_ToString(@LanguageCode)
								+ '.Description=' + dbo.Aff_ToString(@Description)

		END
		EXEC [dbo].[Aff_WriteLog] 
				@Creator = @Updatedby,
				@AffID = @Updatedby,
				@Typename = 'Resources',
				@SPName = @SPName,
				@Details = @Detail,
				@IP = @IP
END


GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTranslationInsOrUpdate] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationInsOrUpdate] TO [vnteam]