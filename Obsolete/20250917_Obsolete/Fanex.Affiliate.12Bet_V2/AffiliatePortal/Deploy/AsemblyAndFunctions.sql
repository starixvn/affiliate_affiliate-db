USE [AffPortal_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[GetMaxWidgetOrderNo]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 13/10/2010
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetMaxWidgetOrderNo]
(
	-- Add the parameters for the function here
	@pageId uniqueidentifier,
	@bucket nvarchar(256)
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @maxOrderNo int

	-- Add the T-SQL statements to compute the return value here
	SELECT @maxOrderNo = max(orderNo)
	FROM PageEmbeddableTemps
	WHERE pageId = @pageId and bucket = @bucket
	
	IF @maxOrderNo is null
		set @maxOrderNo = 0
	RETURN @maxOrderNo

END
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
create function  [dbo].[strSplit] ( @string nvarchar( 4000), @splitter char( 1) )
returns @res table ( id int primary key, rank int, val nvarchar( 4000) )
as
begin
	 if substring ( @string, len ( @string), 1)<>@splitter
		  set @string= @string+@splitter
	 declare @start int, @word nvarchar(4000), @charindex int, @i int
	 set @i=1
	 set @start=1
	 set @charindex= charindex( @splitter, @string, @start)
	 while (@charindex <> 0)begin
		  set @word= substring( @string, @start, @charindex - @start)
		  set @start= @charindex +1
		  set @charindex= charindex( @splitter, @string, @start)
		  insert into @res  values ( @start, @i, @word)
		  set @i=@i+1
	 end
	 return
end
GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Split] (
@StringToSplit varchar(2048),
@Separator varchar(128))
returns table as return
with indices as
(
select 0 S, 1 E
union all
select E, charindex(@Separator, @StringToSplit, E) + len(@Separator)
from indices
where E > S
)
select substring(@StringToSplit,S,
case when E > len(@Separator) then e-s-len(@Separator) else len(@StringToSplit) - s + 1 end) String
,S StartIndex        
from indices where S >0
GO
/****** Object:  UserDefinedFunction [dbo].[CLRSplitStringFunction]    Script Date: 11/12/2010 15:36:57 ******/
CREATE FUNCTION [dbo].[CLRSplitStringFunction](@String [nvarchar](max), @Seperator [nvarchar](max), @IsRemoveEmpty [bit])
RETURNS  TABLE (
	[string] [nvarchar](max) NULL
) WITH EXECUTE AS CALLER
AS 
EXTERNAL NAME [SqlCLRClassLibrary].[UserDefinedFunctions].[Split]
GO
/****** Object:  UserDefinedFunction [dbo].[GetMaxMenuOrderNo]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetMaxMenuOrderNo]
(
	-- Add the parameters for the function here
	@siteId int,
	@parentId int,
	@level tinyint
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	DECLARE @maxOrderNo int

	-- Add the T-SQL statements to compute the return value here
	Set @maxOrderNo = (SELECT max(orderNo)
		FROM MenuTemps
		Where siteId = @siteId and parentId = parentId and [level] = @level)
	if @maxOrderNo is null
		set @maxOrderNo = -1
	RETURN @maxOrderNo

END
GO
/****** Object:  UserDefinedFunction [dbo].[MenuHasChild]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date, ,>
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[MenuHasChild]
(
	-- Add the parameters for the function here
	@menuId int
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	declare @hasChild bit, @count int
	set @hasChild = 0
	
	if (select count(*)
		from MenuTemps
		where parentId = @menuId) > 0
	
	set @hasChild = 1
	
	return @hasChild

END
GO
/****** Object:  UserDefinedFunction [dbo].[GetParentMenuId]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	<Description, ,>
-- =============================================
CREATE FUNCTION [dbo].[GetParentMenuId]
(
	-- Add the parameters for the function here
	@menuId int
)
RETURNS int
AS
BEGIN
	-- Declare the return variable here
	declare @result int

	-- Add the T-SQL statements to compute the return value here
	select @result = parentId
	from MenuTemps
	where menuId = @menuId

	-- Return the result of the function
	RETURN @result

END
GO
/****** Object:  UserDefinedFunction [dbo].[IsChildMenu]    Script Date: 11/12/2010 15:36:57 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		Smith
-- Create date: 10/25/2010
-- Description:	Check if menuId is a child of me or not
-- =============================================
CREATE FUNCTION [dbo].[IsChildMenu]
(
	-- Add the parameters for the function here
	@siteId int,
	@me int,
	@menuId int
)
RETURNS bit
AS
BEGIN
	-- Declare the return variable here
	declare @result bit
	declare @parentOfChild int
	
	if @menuId = @me
		set @result = 1
	else
	begin		
		select @parentOfChild = parentId
		from MenuTemps
		where menuId = @menuId
		
		if @parentOfChild is null or @parentOfChild = 0
		begin
			set @result = 0
		end
		else if @parentOfChild = @me
		begin
			set @result = 1
		end
		else
		begin
			while @parentOfChild <> @me and @parentOfChild is not null
			begin	
				select @parentOfChild = parentId
				from MenuTemps
				where menuId = @parentOfChild
				
				if @parentOfChild = @me
				begin
					set @result = 1
					break
				end
			end
		end
		
	end

	-- Add the T-SQL statements to compute the return value here
	

	-- Return the result of the function
	if @result is null
		set @result = 0
	RETURN @result

END
GO
