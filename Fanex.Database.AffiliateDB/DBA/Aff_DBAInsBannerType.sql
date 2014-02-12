 ALTER PROCEDURE [dbo].[Aff_DBAInsBannerType]
	@TypeName varchar(50),
	@Value varchar(50) 
AS
--DB: DB052.Affiliate_ZZun
SET NOCOUNT ON
IF Exists(Select 1 From BannerTypes with(nolock) Where Type=@TypeName and Value=@Value)
BEGIN
    print N'Value  already exist'	
END
ELSE
BEGIN
	Declare @MaxOrder int
	Select @MaxOrder=max(displayorder) From BannerTypes with(nolock) where Type=@TypeName
	INSERT INTO BannerTypes(type,value,displayorder)values(@typename,@value,@maxorder+1)
	IF @@Error <> 0 
	BEGIN
	     print N'Error occurs.Insert unsuccessfully.'		
		return
	END 	
END

GO
GRANT EXECUTE ON [dbo].[Aff_DBAInsBannerType] TO [vnteam]
GO
GRANT VIEW DEFINITION ON [dbo].[Aff_DBAInsBannerType] TO [vnteam]
GO
