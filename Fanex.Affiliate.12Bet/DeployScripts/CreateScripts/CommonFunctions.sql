 USE [Affiliate_12BET]
GO
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 10/28/2009 06:20:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
create function [dbo].[Split] (
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
/****** Object:  UserDefinedFunction [dbo].[Aff_ToString]    Script Date: 10/28/2009 06:20:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_ToString] (
 @Value sql_variant
)
RETURNS nvarchar(4000)
AS
/*
    DB : DB02.bodb02, DB03.on_user,DB052.Affiliate_12BET
	Task : Convert a value to string for all data types
	Author : Peter@20090909
	
*/
BEGIN	   
	return cast(isnull(@Value,'') as nvarchar(4000))
END
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit]    Script Date: 10/28/2009 06:20:08 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create function  [dbo].[strSplit] ( @string nvarchar( 4000), @splitter char( 1) )
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
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSportID]    Script Date: 10/28/2009 06:20:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetSportID] (
@SportName varchar(2048))
RETURNS smallint
AS
/*
	Task : Get Sport ID
	Author : Peter@20090909
	
*/
BEGIN	
	DECLARE @SportID smallint	
	SELECT @SportID=SportID from SportType with (nolock)
    where SportName=@SportName
	RETURN @SportID
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetAffBalance]    Script Date: 10/28/2009 06:20:06 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetAffBalance] (
@AffID int)
RETURNS money
AS
/*
	Task : Get Balance Brought Forward for Affiliate
	Author : Peter@20090909
	
*/
BEGIN	
   Declare @BalBroughtForward money
	select @BalBroughtForward=sum(Amount)
	from AffTrans (nolock)
	where AffID=@AffId and status in ('approved','pending','completed')  
	return isnull(@BalBroughtForward,0)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetLogType]    Script Date: 10/28/2009 06:20:07 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetLogType] (
@LogName varchar(2048))
RETURNS int
AS
/*
	Task : Get Log Type
	Author : Peter@20090909
	
*/
BEGIN	
	DECLARE @LogType int	
	SELECT @LogType=TypeID from LogType (nolock)
    where TypeName=@LogName
	RETURN @LogType
END
GO
