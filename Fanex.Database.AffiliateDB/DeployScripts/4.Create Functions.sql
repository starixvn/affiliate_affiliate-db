USE Affiliate_Licensee
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetProductID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetProductID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetMemberWinlost]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetMemberWinlost]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetMemberPSP]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetMemberPSP]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetExchangeID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetExchangeID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[InitCap]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[InitCap]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IPConvertToNumber]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[IPConvertToNumber]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[IsZeroCommissionGroup]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[IsZeroCommissionGroup]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetMaxWinlostdate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetMaxWinlostdate]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Split]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Split]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Row_Count]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Row_Count]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[parseURL]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[parseURL]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[NumberConvertToIP]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[NumberConvertToIP]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetStartDate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetStartDate]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetEndDate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetEndDate]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetSystemCurrencyID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetSystemCurrencyID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetFirstDayOfMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetFirstDayOfMonth]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetSportID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetSportID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetExchangeRate]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetExchangeRate]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_Con_GetGroupItID]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_Con_GetGroupItID]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetAffBalance]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetAffBalance]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_IsProductInGroupOfAff]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_IsProductInGroupOfAff]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_SplitIndex]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_SplitIndex]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[strSplit_Key]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[strSplit_Key]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_IPConvertToNumber]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_IPConvertToNumber]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_CountMember]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_CountMember]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_PlayerCurrencyByAffId]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_PlayerCurrencyByAffId]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetDeductionPercent]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetDeductionPercent]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Date_Only]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Date_Only]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetQMTurnOver]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetQMTurnOver]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_HasDeduction]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_HasDeduction]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_ToString]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_ToString]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[strSplit]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[strSplit]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetSettingValue]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetSettingValue]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetCurrencyCode]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetCurrencyCode]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetLastDayOfMonth]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetLastDayOfMonth]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetLogType]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetLogType]
GO
IF  EXISTS (SELECT * FROM sys.objects WHERE object_id = OBJECT_ID(N'[dbo].[Aff_GetSmallDatetime]') AND type in (N'FN', N'IF', N'TF', N'FS', N'FT'))
DROP FUNCTION [dbo].[Aff_GetSmallDatetime]


GO


/****** Object:  UserDefinedFunction [dbo].[Aff_GetLastDayOfMonth]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetLastDayOfMonth] (  
@Date datetime)  
RETURNS datetime  
AS  
  
BEGIN    
 RETURN DATEADD(s,-60, DATEADD(mm, DATEDIFF(m,0,@Date)+1,0))
 
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetFirstDayOfMonth]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetFirstDayOfMonth] (
@Date datetime)
RETURNS datetime
AS
BEGIN		
	RETURN CONVERT(VARCHAR(25),DATEADD(dd,-(DAY(@Date)-1),@Date),101)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetEndDate]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetEndDate] (
@Date datetime)
RETURNS datetime
AS

BEGIN		
	RETURN dateadd(ms, -3, dateadd(d, datediff(d, 0, @Date) + 1, 0)) 
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSmallDatetime]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetSmallDatetime] (
@Date datetime)
RETURNS datetime
AS
BEGIN		
	RETURN cast (convert(varchar(10),@Date,120) as smalldatetime)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetStartDate]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetStartDate] (
@Date datetime)
RETURNS datetime
AS
BEGIN		
	RETURN dateadd(d, datediff(d, 0, @Date), 0) 
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_IPConvertToNumber]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_IPConvertToNumber] (
	@IP varchar(22)
)
RETURNS bigint
AS
/*
    DB : DB05.Affiliate_MYM
	Task : Convert IP format to integer number
	Author : Peter@20100127
	
*/
BEGIN	   
	SET @IP=ltrim(rtrim(@IP))
	If(@Ip LIKE '%_%.%_%.%_%.%_%')
	Begin
		Declare @IpA bigint, @IpB int, @IpC int, @IpD int, @IpI bigint
		
		Select @IpA = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpA) - 1)
		
		Select @IpB = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpB) - 1)
		
		Select @IpC = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpC) - 1)
		
		Select @IpD = @Ip
		
		Return (@IpA * 256*256*256) + (@IpB * 256 * 256) + (@IpC * 256) + @IpD	
	End
	Return 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit_Key]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS OFF
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function  [dbo].[strSplit_Key] ( @string nvarchar( 4000), @splitter char( 1) )
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
GO
/****** Object:  UserDefinedFunction [dbo].[strSplit]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE function  [dbo].[strSplit] ( @string nvarchar( 4000), @splitter char( 1) )
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
/****** Object:  UserDefinedFunction [dbo].[Split]    Script Date: 07/17/2013 02:03:54 ******/
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
/****** Object:  UserDefinedFunction [dbo].[Row_Count]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Row_Count] (@table_name sysname)
-- @table_name we want to get count

RETURNS bigint
/*
-------------------------------------------------------
-- Function Name: row_count
-- Author: Mohamed Hassan
-- Email: moh_hassan20@yahoo.com
-- Development Date: 08/11/2008
-- Version: 1.0
-- Description: Return row count of the whole table, as a replacement for count(*) , give extra performance  at least 70% over , than count(*) for large tables with millions of rows
-- SQL Server: SQL server 2005
-- Usage Example: select dbo.row_count ('Sales.SalesOrderDetail')
-- Copyright:
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as
published by the Free Software Foundation, either version 3 of the
License, or any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
-------------------------------------------------------
*/
AS
BEGIN
DECLARE @nn bigint -- number of rows

IF @table_name IS NOT NULL 
BEGIN
 SELECT  @nn = sum(  p.rows )  
 FROM sys.partitions p
 LEFT JOIN  sys.allocation_units a ON  p.partition_id = a.container_id
 WHERE
  p.index_id  in(0,1) -- 0 heap table , 1 table with clustered index
       and p.rows is not null
  and a.type = 1  -- row-data only , not LOB
  and p.object_id = object_id(@table_name)    
 END 
RETURN (@nn)
END
GO
/****** Object:  UserDefinedFunction [dbo].[parseURL]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[parseURL]  (@strURL varchar(1000))
RETURNS varchar(1000)
AS
BEGIN
IF CHARINDEX('http://',@strURL) > 0 OR CHARINDEX('https://',@strURL) > 0
-- Ghetto-tastic
SELECT @strURL = REPLACE(@strURL,'https://','')
SELECT @strURL = REPLACE(@strURL,'http://','')
SELECT @strURL = REPLACE(@strURL,'www','')
-- Remove everything after "/" if one exists
IF CHARINDEX('/',@strURL) > 0 (SELECT @strURL = LEFT(@strURL,CHARINDEX
('/',@strURL)-1))

-- Optional: Remove subdomains but differentiate between www.google.com and www.google.com.au
IF (LEN(@strURL)-LEN(REPLACE(@strURL,'.','')))/LEN('.') < 3 -- if there are less than 3 periods

SELECT @strURL = PARSENAME(@strURL,2) + '.' + PARSENAME(@strURL,1)
ELSE -- It's likely a google.co.uk, or google.com.au
SELECT @strURL = PARSENAME(@strURL,3) + '.' + PARSENAME(@strURL,2) + '.' + 
PARSENAME(@strURL,1)
RETURN @strURL
END
GO
/****** Object:  UserDefinedFunction [dbo].[NumberConvertToIP]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[NumberConvertToIP] (
	@Number bigint
)
RETURNS varchar(30)
AS
/*
     DB :Affiliate_LB365
	Task : Convert a number to ip string
	Author : Peter@20100127
	
*/
BEGIN	 
    declare @IpA int,  @IpB int,@IpC int,@IpD int,@Result varchar(30)
    
	
    SET @IpA=(@Number-@Number%16777216)/16777216
    SET @IpB=(@Number%16777216-(@Number%16777216)%65536)/65536
    SET @IpC = ((@Number%16777216) % 65536 - ((@Number % 16777216) % 65536 % 256)) / 256;
    SET @IpD = (@Number % 16777216) % 65536 % 256;
    SET @Result= cast(@IpA as varchar(3)) + '.' + cast(@IpB as varchar(3)) + '.' 
                 + cast(@IpC as varchar(3)) + '.' + cast(@IpD as varchar(3))
	
	Return @Result
END
GO
/****** Object:  UserDefinedFunction [dbo].[IPConvertToNumber]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[IPConvertToNumber] (
	@IP varchar(30)
)
RETURNS bigint
AS
/*
    DB :Affiliate_LB365
	Task : Convert IP format to integer number
	Author : Peter@20100127
	
*/
BEGIN	   
	SET @IP=ltrim(rtrim(@IP))
	If(@Ip LIKE '%_%.%_%.%_%.%_%')
	Begin
		Declare @IpA bigint, @IpB int, @IpC int, @IpD int, @IpI bigint
		
		Select @IpA = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpA) - 1)
		
		Select @IpB = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpB) - 1)
		
		Select @IpC = Left(@Ip, PATIndex('%.%', @IP) - 1)	
		Select @Ip = Right(@Ip, Len(@Ip) - Len(@IpC) - 1)
		
		Select @IpD = @Ip
		
		Return (@IpA * 256*256*256) + (@IpB * 256 * 256) + (@IpC * 256) + @IpD	
	End
	Return 0
END
GO
/****** Object:  UserDefinedFunction [dbo].[InitCap]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[InitCap] ( @InputString varchar(4000) ) 
RETURNS VARCHAR(4000)
AS
BEGIN

DECLARE @Index          INT
DECLARE @Char           CHAR(1)
DECLARE @PrevChar       CHAR(1)
DECLARE @OutputString   VARCHAR(255)

SET @OutputString = LOWER(@InputString)
SET @Index = 1

WHILE @Index <= LEN(@InputString)
BEGIN
    SET @Char     = SUBSTRING(@InputString, @Index, 1)
    SET @PrevChar = CASE WHEN @Index = 1 THEN ' '
                         ELSE SUBSTRING(@InputString, @Index - 1, 1)
                    END

    IF @PrevChar IN (' ', ';', ':', '!', '?', ',', '.', '_', '-', '/', '&', '''', '(')
    BEGIN
        IF @PrevChar != '''' OR UPPER(@Char) != 'S'
            SET @OutputString = STUFF(@OutputString, @Index, 1, UPPER(@Char))
    END

    SET @Index = @Index + 1
END

RETURN @OutputString

END
GO
/****** Object:  UserDefinedFunction [dbo].[Date_Only]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Date_Only](@DATE datetime)
RETURNS Datetime
WITH EXECUTE AS CALLER
AS
BEGIN
     return dateadd(dd, datediff(dd,0, @DATE), 0)
     
END;
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_ToString]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_ToString] (
 @Value sql_variant
)
RETURNS nvarchar(max)
AS
/*
    DB : DB02.bodb02, DB03.on_user,DB03.bodb02,DB052.Affiliate_MYM
	Task : Convert a value to string for all data types
	Author : Peter@20090909
	
*/
BEGIN	   
	return cast(isnull(@Value,'') as nvarchar(max))
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_SplitIndex]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_SplitIndex]
 (@string NVARCHAR(4000), @splitter CHAR, @index INT)  
RETURNS NVARCHAR(4000) AS  
BEGIN 

	IF SUBSTRING(@string, len(@string), 1) <> @splitter
		SET @string = @string + @splitter

	DECLARE @word NVARCHAR(4000) SET @word = ''
	DECLARE @start INT SET @start = 1
	DECLARE @i INT SET @i = 1
	DECLARE @charindex INT SET @charindex = CHARINDEX(@splitter, @string, @start)

	WHILE (@charindex <> 0)
	BEGIN
          SET @word= SUBSTRING(@string, @start, @charindex - @start)
          SET @start= @charindex + 1
          SET @charindex= CHARINDEX(@splitter, @string, @start)
		  IF @i = @index RETURN @word
          SET @i=@i+1
    END

	Return @string

END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_PlayerCurrencyByAffId]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_PlayerCurrencyByAffId]
(@AffId int)
RETURNS varchar(50)
AS
BEGIN

Declare @PlayerCurrency varchar(50)

select 
	@PlayerCurrency = (
						Select Code 
						From Exchange nolock
						Where ExchangeID =
								(
								Select ExchangeId 
								from [CurrencyConverter] nolock
								where PartnerCurrency = 
									(
									Select Player_Currency
									from AffDetail nolock
									where AffId = @AffId
									)
								)
						)
return @PlayerCurrency
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_IsProductInGroupOfAff]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_IsProductInGroupOfAff] (  
@AffID int,@ProductID int ,@MonthDate datetime=null)  
RETURNS int  
AS  
BEGIN   
if @MonthDate>CURRENT_TIMESTAMP
  return 0
 Select @MonthDate=coalesce(@MonthDate,current_timestamp)  
 select @MonthDate=[dbo].[Aff_GetLastDayOfMonth](@MonthDate)  
 select @MonthDate=dbo.Aff_GetSmallDatetime(@MonthDate)  
 declare @Result int  
   
 if(datediff(m,@MonthDate,current_timestamp)>=0)  
 begin  
  select @Result=count(distinct c.ProductID)
  from AffInfo a with(nolock)  
  inner join GroupSetting c with(nolock) on a.GroupId = c.GroupId  
  where AffId = @AffId and  c.ProductID=@ProductID
 end  
 else  
 begin  
   select @Result=count(distinct c.ProductID) 
  from AffGroupHistory a with(nolock)  
  inner join GroupSettingHistory c with(nolock) on a.GroupId = c.GroupId  
  where a.AffId = @AffId and a.MonthDate=@MonthDate and c.MonthDate=@MonthDate and  c.ProductID=@ProductID  

 end  
   
     
 return isnull(@Result,0)  
END
GO
/****** Object:  UserDefinedFunction [dbo].[IsZeroCommissionGroup]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[IsZeroCommissionGroup]  
(  
    @GroupID int,
    @MonthDate datetime  
)  
RETURNS bit
AS   
/*
   - 20120514@Peter : Check all the setting commission is Zero only			 

*/
BEGIN  
 
Declare @Result bit

set @Result=0
if datediff(m,current_timestamp,@MonthDate)>=0 
begin
   if(not exists (select top(1) 1 from GroupSetting (nolock) where groupid=@GroupID and commission <> 0))
      set @Result=1
end
else 
begin
    if(not exists (select top(1) 1 from GroupSettingHistory (nolock) where groupid=@GroupID and datediff(m,monthdate,@MonthDate) =0 and commission <> 0))
      set @Result=1
end

return isnull(@Result,0) 


END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_HasDeduction]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_HasDeduction] (
@GroupID int,@ProductID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)
RETURNS bit
AS
/*
	Task : Check a sport has a deduction name
	Author : Peter@20090909
	@MonthDate=null : current month
*/
BEGIN	 
    
    select @MonthDate=isnull(@MonthDate,current_timestamp) 
    if(datediff(m,current_timestamp,@MonthDate)<0)
    BEGIN
	   if(exists (select top(1) 1 
				  from DeductionSettingHistory with (nolock) 
				  where GroupID=@GroupID 
						and datediff(m,MonthDate,@MonthDate)=0 
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where ProductID=@ProductID and DTypeName=@DeductionName) 
				   )
			)
		  return 1
	   else
		 return 0
	END
	ELSE
	BEGIN
	   if(exists (select top(1) 1 
				  from DeductionSetting with (nolock) 
				  where GroupID=@GroupID 						
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where ProductID=@ProductID and DTypeName=@DeductionName) 
				   )
			)
		  return 1
	   else
		 return 0
	END
		 
   return 0 
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSystemCurrencyID]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetSystemCurrencyID]()
RETURNS smallint
AS
BEGIN
	declare @SystemCurrencyID smallint

	select @SystemCurrencyID=e.exchangeid
	from Exchange e (nolock)
	  inner join SystemSettings s (nolock) on s.SValue=e.Code
	where s.Type='Meta' and s.SName='SystemCurrency'

	return @SystemCurrencyID
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSportID]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetSportID] (  
	@ProductName varchar(2048))  
RETURNS smallint  
AS  
/*  
 Task : Get Sport ID  
 Author : Peter@20090909  
   
*/  
BEGIN   
	DECLARE @ProductID smallint   
	SELECT @ProductID=ProductID from Product with (nolock)  
	where ProductName=@ProductName  
	RETURN @ProductID  
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetMaxWinlostdate]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetMaxWinlostdate] (
@AffID int,@ProductID tinyint,@MonthDate smalldatetime)
RETURNS smalldatetime
AS
/*
	Task : Get the current max winlostdate for a specific month of affiliate
	Author : Peter@20101126
	@MonthDate=null : current month
*/
BEGIN	 
    
   select @MonthDate=isnull(@MonthDate,current_timestamp) 
   
   declare @MaxWinlostDate smalldatetime
   select @MaxWinlostDate=max(winlostdate)
   from AffDailySummary (nolock) 
		where datediff(m,winlostdate,@MonthDate)=0
			 and AffID=	@AffID and ProductID=@ProductID
			 
   return @MaxWinlostDate
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetLogType]    Script Date: 07/17/2013 02:03:54 ******/
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
/****** Object:  UserDefinedFunction [dbo].[Aff_GetSettingValue]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetSettingValue](
	@Type varchar(50),
	@Key varchar(50),
    @Environment varchar(50)=NULL
)
RETURNS nvarchar(max)
AS
BEGIN
    
	DECLARE @value nvarchar(max)
	select @value = SValue
	FROM SystemSettings (nolock)
	WHERE Type=@Type and SName=@Key and (@Environment is null or Environment=@Environment)
	
	return @value
END;
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetQMTurnOver]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetQMTurnOver] (
@AffID int,@MonthDate datetime=null)
RETURNS money
AS
/*
	Task : Get Balance Brought Forward for Affiliate
	Author : Peter@20090909
	
*/
BEGIN	
	Select @MonthDate=coalesce(@MonthDate,current_timestamp)
	select @MonthDate=[dbo].[Aff_GetLastDayOfMonth](@MonthDate)
	select @MonthDate=dbo.Aff_GetSmallDatetime(@MonthDate)
	declare @QMTurnover money
	
	if(datediff(m,@MonthDate,current_timestamp)>=0)
	begin
		select @QMTurnover = QualifiedAmount
		from AffInfo a with(nolock)
		inner join CommGroup c with(nolock) on a.GroupId = c.GroupId
		where AffId = @AffId
	end
	else
	begin
		select @QMTurnover = QualifiedAmount
		from AffGroupHistory a with(nolock)
		inner join CommGroupHistory c with(nolock) on a.GroupId = c.GroupId
		where a.AffId = @AffId and a.MonthDate=@MonthDate and c.MonthDate=@MonthDate
	end
	
   
	return isnull(@QMTurnover,0)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetProductID]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetProductID] (
@ProductName varchar(2048))
RETURNS smallint
AS
/*
	Task : Get Product ID
	Author : Peter@20090909
	
*/
BEGIN	
	DECLARE @ProductID smallint	
	SELECT @ProductID=ProductID from Product with (nolock)
    where ProductName=@ProductName
	RETURN @ProductID
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetMemberWinlost]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetMemberWinlost] (
@AffID int,@ProductID tinyint, @MonthDate smalldatetime)
RETURNS money
AS
/*
	Task : Get MemberWinlost for Affiliate
	Author : Peter@20100508
	@MonthDate=null : current month
*/
BEGIN	 
    declare @MemberWinlost money
    select @MemberWinlost=0
    
    If Datediff(m, @monthdate, current_timestamp) = 0
    BEGIN
            Declare @Today smalldatetime,@FirstDay smalldatetime,@LastDay smalldatetime

			Select @FirstDay = cast(cast(year(getdate()) as varchar(5)) + '-' + cast(Month(getdate()) as varchar(5)) + '-' +'1' as smalldatetime)
			--Get last day of inputted month
			Select @Today = convert (varchar(12),current_timestamp)
			select @LastDay=@Today 
			
			select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(AffExRate,0))
			from AffDaily (nolock) 
			where AffId=@AffID and ProductID=@ProductID and winlostdate between @FirstDay and @LastDay
			
    END
    ELSE
    BEGIN
        Declare @MaxTransDate smalldatetime	
	    select @MaxTransDate = Max(winlostdate) From AffCommission(nolock)
	    If @MaxTransDate < @monthdate
			BEGIN
		        select @MemberWinlost=sum(isnull(MemWinlost,0) * isnull(AffExRate,0))
				from AffDaily (nolock) 
				where AffId=@AffID and ProductID=@ProductID and datediff(m,WinlostDate,@MonthDate) = 0
			END
	    ELSE
			BEGIN
		        Select @MemberWinlost = isnull(MemberWinlost, 0) From AffCommission(nolock) where AffId = @AffId and WinlostDate = @monthdate and ProductID=@ProductID
			END
    END    
		 
    return  isnull(@MemberWinlost,0)
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetDeductionPercent]    Script Date: 07/17/2013 02:03:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetDeductionPercent] (
@AffID int,@ProductID tinyint, @DeductionName nvarchar(50),@MonthDate smalldatetime)
RETURNS float
AS
/*
	Task : Check a sport has a deduction name
	Author : Peter@20090909
	@MonthDate=null : current month
*/
BEGIN	 
    declare @percent float,@GroupID int
    select @percent=null
    
   select @MonthDate=isnull(@MonthDate,current_timestamp) 
   if(datediff(m,current_timestamp,@MonthDate)<0)
    BEGIN
       select @GroupID=GroupID
       from AffGroupHistory with (nolock)
       where AffID=@AffID and datediff(m,MonthDate,@MonthDate)=0
       
       select @percent= DeductedPercentage
       from DeductionSettingHistory with (nolock) 
				  where GroupID=@GroupID 
						and datediff(m,MonthDate,@MonthDate)=0
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where ProductID=@ProductID and DTypeName=@DeductionName)
	END
	ELSE
	BEGIN
	   select @GroupID=GroupID
       from AffInfo with (nolock)
       where AffID=@AffID
       
	   select @percent= DeductedPercentage
       from DeductionSetting with (nolock) 
				  where GroupID=@GroupID 						
						and DeductionID= (select top(1) DTypeID
										   from DeductionType 
										   where ProductID=@ProductID and DTypeName=@DeductionName)       
	END
	if(@percent is NULL)
		set @percent=0
   return @percent
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetCurrencyCode]    Script Date: 07/17/2013 02:03:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetCurrencyCode](
	@ExchangeID smallint
)
RETURNS varchar(5)
AS
BEGIN
	DECLARE @code varchar(5)
	select @code = Code
		
	FROM Exchange(nolock)
	WHERE ExchangeID = @ExchangeID
	
	return @code
END;
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetAffBalance]    Script Date: 07/17/2013 02:03:53 ******/
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
/****** Object:  UserDefinedFunction [dbo].[Aff_CountMember]    Script Date: 07/17/2013 02:03:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_CountMember] (
@AffID int)
RETURNS int
AS
/*
	Task : Count number of members for Affiliate
	Author : Peter@20090909
	
*/
BEGIN	
   Declare @count int
	
	select @count=Sum(1)
   from MemberInfo with (nolock)  
   where AffID=@AffID and IsRemoved = 0   
  return @count
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_Con_GetGroupItID]    Script Date: 07/17/2013 02:03:53 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_Con_GetGroupItID]
(
)
RETURNS INT
AS
BEGIN
	Declare @GroupIT int
	Select @GroupIt = GroupID from AffGroupInfo nolock where GroupName = 'Aff_IT_Dept'

	RETURN @GroupIT
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetExchangeID]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetExchangeID](
	@Code varchar(5)
)
RETURNS smallint
AS
BEGIN
	DECLARE @ExchangeID smallint
	select @ExchangeID = ExchangeID
		
	FROM Exchange(nolock)
	WHERE Code = @Code
	
	return @ExchangeID
END;
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetExchangeRate]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE FUNCTION [dbo].[Aff_GetExchangeRate](  
    @FromCurrency smallint,  
	@ToCurrency smallint,
	@Date smalldatetime = null
 )  
 RETURNS float  
AS  
/*  
   Get ExchangeRate @FromCurrency to @ToCurrency  
*/  
BEGIN  

if @FromCurrency=@ToCurrency
  return 1

   -- check @ToCurrency is a base-currency  
select @Date = ISNULL(@Date, current_timestamp)

select @Date = dbo.Date_Only(@Date)

Declare @TmpExchange table([ExchangeID] [smallint],
								[USD] [float], [USD_Market] [float],
								[EUR] [float], [EUR_Market] [float],
								[CNY] [float], [CNY_Market] [float],
								[UUS] [float], [UUS_Market] [float],
								[MYR] [float], [MYR_Market] [float],
								[SGD] [float], [SGD_Market] [float],
								[IDR] [float], [IDR_Market] [float],
								[AUD] [float], [AUD_Market] [float],
								[CHF] [float], [CHF_Market] [float],
								[GBP] [float], [GBP_Market] [float],
								[THB] [float], [THB_Market] [float],
								[VND] [float], [VND_Market] [float],
								[Code] [varchar](5), [DepositPercent] [float],
								[WithdrawalPercent] [float], [IsAutoRefresh] [bit])

If(DATEDIFF(D, @Date, CURRENT_TIMESTAMP) = 0)
begin
	insert into @TmpExchange
	Select [ExchangeID],
			[USD], [USD_Market],
			[EUR], [EUR_Market],
			[CNY], [CNY_Market],
			[UUS], [UUS_Market],
			[MYR], [MYR_Market],
			[SGD], [SGD_Market],
			[IDR], [IDR_Market],
			[AUD], [AUD_Market],
			[CHF], [CHF_Market],
			[GBP], [GBP_Market],
			[THB], [THB_Market],
			[VND], [VND_Market],
			[Code], [DepositPercent],
			[WithdrawalPercent], [IsAutoRefresh]
	from Exchange nolock
end
Else
Begin
	insert into @TmpExchange
	Select [ExchangeID],
			[USD], [USD_Market],
			[EUR], [EUR_Market],
			[CNY], [CNY_Market],
			[UUS], [UUS_Market],
			[MYR], [MYR_Market],
			[SGD], [SGD_Market],
			[IDR], [IDR_Market],
			[AUD], [AUD_Market],
			[CHF], [CHF_Market],
			[GBP], [GBP_Market],
			[THB], [THB_Market],
			[VND], [VND_Market],
			[Code], [DepositPercent],
			[WithdrawalPercent], [IsAutoRefresh]
	from ExchangeDaily nolock
	where Date = @Date
End


declare @Rate float, @FromRate float, @ToRate float, @ToCode varchar(5),@FromCode varchar(5),@SysCurrencyCode varchar(5)  
    
select @ToCode=dbo.Aff_GetCurrencyCode(@ToCurrency),@FromCode=dbo.Aff_GetCurrencyCode(@FromCurrency)  
  
if CHARINDEX(@ToCode,dbo.[Aff_GetSettingValue]('Meta','AFF_SupportedCurrencies',NULL))>0  -- if ToCurrency is in base currencies list for the system
begin  
       
	select @Rate = case @ToCode  
		When 'USD' then USD  
		when 'EUR' then EUR  
		When 'CNY' then CNY  
		when 'UUS' then UUS  
		when 'MYR' then MYR  
		When 'SGD' then SGD
		when 'IDR' then IDR
		When 'AUD' then AUD
		when 'CHF' then CHF
		when 'GBP' then GBP
		when 'THB' then THB
		when 'VND' then VND
		ELSE 0 end  
	FROM @TmpExchange 
	WHERE ExchangeID = @FromCurrency      
  
end  
else if CHARINDEX(@FromCode,dbo.[Aff_GetSettingValue]('Meta','AFF_SupportedCurrencies',NULL))>0 --from currencies is in list base currencies list
begin
     select @Rate = case @FromCode  
		When 'USD' then USD  
		when 'EUR' then EUR  
		When 'CNY' then CNY  
		when 'UUS' then UUS  
		when 'MYR' then MYR  
		When 'SGD' then SGD
		when 'IDR' then IDR
		When 'AUD' then AUD
		when 'CHF' then CHF
		when 'GBP' then GBP
		when 'THB' then THB
		when 'VND' then VND
		ELSE 0 end  
	FROM @TmpExchange 
	WHERE ExchangeID = @ToCurrency      
	
	if @Rate >= 0.0000000000001	
	  select @Rate=1/@Rate 	
	
end

else
begin  
    -- Get SystemCurrency  
    /*   
        1 THB = 0.10670 MYR  
        1 AUD= 3.24 MYR  
    => 1 AUD= ? THB  
    */  
    select @SysCurrencyCode=dbo.[Aff_GetSettingValue]('Meta','SystemCurrency',NULL)  
    select @FromRate = case @SysCurrencyCode  
		When 'USD' then USD  
		when 'EUR' then EUR  
		When 'CNY' then CNY  
		when 'UUS' then UUS  
		when 'MYR' then MYR  
		When 'SGD' then SGD
		when 'IDR' then IDR
		When 'AUD' then AUD
		when 'CHF' then CHF
		when 'GBP' then GBP
		when 'THB' then THB
		when 'VND' then VND 
		ELSE 0 end  
	FROM @TmpExchange   
	WHERE ExchangeID = @FromCurrency  
     
	select @ToRate = case @SysCurrencyCode  
			When 'USD' then USD  
			when 'EUR' then EUR  
			When 'CNY' then CNY  
			when 'UUS' then UUS  
			when 'MYR' then MYR  
			When 'SGD' then SGD
			when 'IDR' then IDR
			When 'AUD' then AUD
			when 'CHF' then CHF
			when 'GBP' then GBP
			when 'THB' then THB
			when 'VND' then VND  
			ELSE 0 end  
	FROM @TmpExchange   
	WHERE ExchangeID = @ToCurrency  

	if @FromRate < 0.0000000000001	
	  select @Rate=0
    else
	    select @Rate=@ToRate/@FromRate    


      
end  
return @Rate  
   
END
GO
/****** Object:  UserDefinedFunction [dbo].[Aff_GetMemberPSP]    Script Date: 07/17/2013 02:03:54 ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE function [dbo].[Aff_GetMemberPSP] (  
@IBCCustID int,@WinlostDate smalldatetime,@ProductID int)  
RETURNS money  
AS  
/*  
 Task : Get PSP fee for member  
           @WinlostDate=null -->get all.Otherwise will get for specific date  
           @ProductID=0 --> Get all. Otherwisw will get for specific sport type   
 Author : Peter@20090909  
   
*/  
BEGIN   
   Declare @PSP money  
     
   select @PSP=Sum(PSP)  
  from MemberDaily with(nolock)    
 where IBCCustID =@IBCCustID            
		and WinlostDate = @WinlostDate
		and ProductID  in (0, @ProductID)
		--and (case when @Winlostdate is null or @WinlostDate=WinlostDate then 1 else 0 end)=1  
       --and (case when @ProductID=0 or @ProductID=ProductID then 1 else 0 end)=1 
   
 return isnull(@PSP,0)  
END
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[Aff_GetSportID] TO [bodbDownlineNetView] AS [dbo]
GO

CREATE function [dbo].[GetCountryIDFromIP] (  
@IP varchar(50))  
RETURNS varchar(5)  
AS  
BEGIN    
  declare @CountryID varchar (5)    
  SET @CountryID=(SELECT top(1)   i.country
         FROM ip2nation i (nolock)             
         WHERE ip < dbo.Aff_IPConvertToNumber(@IP) 
         ORDER BY ip DESC)
 
  SET @CountryID=coalesce(@CountryID,'-')

   return upper(@CountryID)
END
GO
GRANT EXECUTE ON [dbo].[GetCountryIDFromIP] TO [bodbAdminNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCountryIDFromIP] TO [bodbDownlineNet] AS [dbo]
GO
GRANT EXECUTE ON [dbo].[GetCountryIDFromIP] TO [bodbDownlineNetView] AS [dbo]
GO