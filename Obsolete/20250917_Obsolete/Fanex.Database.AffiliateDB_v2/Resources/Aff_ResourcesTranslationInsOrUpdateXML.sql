 
----------------------------------------------------------------------------------------------------
/*Insert Or Update Translation Resource from excel file*/

ALTER PROCEDURE Aff_ResourcesTranslationInsOrUpdateXML
	@Updatedby int ,
	@XmlData XML,--<root><res><key></key><type></type><value></value><code></code><des></des></res></root>
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
	IF(@XmlData IS NULL)
		BEGIN
			SELECT @ErrMsg = N'Error! Data xml is empty!', @ErrCode = 1002
			RETURN
		END
	DECLARE @ResourceKey VARCHAR(50)
	DECLARE @ResourceValue NVARCHAR(MAX)
	DECLARE @RefID VARCHAR(50)
	DECLARE @LanguageCode VARCHAR(8)
	DECLARE @Description NVARCHAR(100)
	
	DECLARE @HandleID INT
	EXEC sp_xml_preparedocument @HandleID OUTPUT, @XmlData
	
	DECLARE XmlCursor CURSOR FOR
	SELECT * FROM OPENXML (@HandleID, '/root/res', 3) 
	WITH 
	  (ResourceKey VARCHAR(50) 'key',
	   ResourceValue NVARCHAR(MAX) 'value',
	   RefID VARCHAR(50) 'type',
	   LanguageCode VARCHAR(8) 'code',
	   Description NVARCHAR(100) 'des'
	  )

	OPEN XmlCursor
	FETCH NEXT FROM XmlCursor INTO @ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description

	WHILE @@FETCH_STATUS = 0
	BEGIN
		EXEC Aff_ResourcesTranslationInsOrUpdate @Updatedby,@ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description,@IP,@ID OUTPUT,@ErrCode OUTPUT,@ErrMsg OUTPUT
		IF (@ErrCode <> 0)
		BEGIN
			CLOSE XmlCursor
			DEALLOCATE XmlCursor
			EXEC sp_xml_removedocument @HandleID
			RETURN 
		END
		FETCH NEXT FROM XmlCursor INTO @ResourceKey,@ResourceValue,@RefID,@LanguageCode,@Description
	END

	CLOSE XmlCursor
	DEALLOCATE XmlCursor
	EXEC sp_xml_removedocument @HandleID
	
END

GO
GRANT EXECUTE ON [dbo].[Aff_ResourcesTranslationInsOrUpdateXML] TO [bodbAdminNet]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_ResourcesTranslationInsOrUpdateXML] TO [vnteam]