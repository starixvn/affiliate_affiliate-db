/****** Object:  UserDefinedFunction [dbo].[strSplit_Key]    Script Date: 12/16/2010 10:17:01 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO


ALTER function  [dbo].[strSplit_Key] ( @string nvarchar( 4000), @splitter char( 1) )
returns @res table (val int PRIMARY KEY)
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
          insert into @res  values ( @word)
          set @i=@i+1
     end
     return
end




