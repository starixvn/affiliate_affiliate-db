ALTER Procedure [dbo].[Aff_ResourceKeyIns]
	@Updatedby int ,
	@Key varchar(50),
	@Value nvarchar(max),
	@Type varchar(50),
	@LanguageCode varchar(8)=null,
	@Description nvarchar(100),
	@IP nvarchar(15)='',
	@ID uniqueidentifier='00000000-0000-0000-0000-000000000000' OUTPUT,
	@ErrCode int = 0 OUTPUT,
	@ErrMsg nvarchar(4000) = '' OUTPUT
as
begin 
/*
Created: 20090122@Peter
Task : [description of SP]
DB: DB052.Affiliate_MYM
Original:

Revisions:
- 20090122@[Reviewer]: [Description of revision] 

Param's Explanation:


• @ErrCode:
= 0: Transaction recorded successfully.
> 0: Insert  unsuccessfully!

• @ErrMsg: Error description.
*/
SET NOCOUNT ON

	EXEC [dbo].[Aff_Con_CheckPermission]
		@custid=@Updatedby,@funcname='[Resources]',
		@System = 'AFFILIATE',
		@ErrCode=@ErrCode output,
		@ErrMsg=@ErrMsg output	
	
If @ErrCode <> 0
	RETURN

--Check Type
--Check LanguageCode
--Check Key
--Check Value
	
If(Exists (Select 1 from RefResources (nolock) where RefID=@Type and 
	(@LanguageCode is null or [LanguageCode]=@LanguageCode) and [ResourceKey]=@Key))
BEGIN
Select @ErrMsg = N'Error! This key is existed!', @ErrCode = 1001
	return
END

if @LanguageCode is not null 
BEGIN
	SELECT @ID = newid()
	INSERT INTO [dbo].[RefResources]
			   ([ResourceID],
				[RefID],
				[LanguageCode],
				[ResourceKey],
				[ResourceValue],
				[Description] )
	values (@ID,@Type,@LanguageCode,@Key,@Value,@Description)			
END

INSERT INTO [dbo].[RefResources]
           ([ResourceID],
			[RefID],
			[LanguageCode],
			[ResourceKey],			
			[ResourceValue],
			[Description] )
Select newid(),@Type,[LanguageID] as LanguageCode,@Key,@Value,@Description			
from Language a (nolock) 
where (@LanguageCode is null or [LanguageID] <> @LanguageCode)
      and not exists (Select 1 from RefResources(nolock)
						where RefID=@Type
							  and LanguageCode = a.LanguageID
							  and [ResourceKey]=@Key	
					 )
			

declare @SPName varchar(50), @Detail nvarchar(4000) 
select @SPName = OBJECT_NAME(@@ProcID)
select @Detail = 'Add new Resource. Key=' + dbo.Aff_ToString(@Key) + '.Value=' + isnull(@Value,'') + '.Type=' + dbo.Aff_ToString(@Type) + '.Language=' + dbo.Aff_ToString(@LanguageCode)
				+ '.Description=' + dbo.Aff_ToString(@Description)

EXEC [dbo].[Aff_WriteLog] 
	@Creator = @Updatedby,
	@AffID = @Updatedby,
	@Typename = 'Resources', -- refer to table LogType
	@SPName = @SPName,
	@Details = @Detail,
	@IP = @IP
	
end
