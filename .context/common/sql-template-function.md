# SQL Function Template

**Usage**: Copy-paste template when creating new functions.

**Environment Reference**: See `sql-environment.md` for serverAlias and executors.

---

## Table-Valued Function Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_FunctionName]
(
    @Param1 DataType,
    @Param2 DataType
)
RETURNS TABLE
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Core function - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize Function [RedmineID: #XXXXXX]

    Parameter's Explanation:
        - @Param1: Description
        - @Param2: Description

    Usage:
        SELECT * FROM dbo.Aff_f_FunctionName(@Param1, @Param2)
*/
RETURN
    SELECT
        Column1,
        Column2,
        Column3
    FROM dbo.SourceTable WITH (NOLOCK)
    WHERE Condition = @Param1
GO
```

---

## Scalar Function Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/
CREATE FUNCTION [dbo].[Aff_f_FunctionName]
(
    @Param1 DataType
)
RETURNS DataType
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Core function - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize Function [RedmineID: #XXXXXX]

    Usage:
        SELECT dbo.Aff_f_FunctionName(@Param1)
*/
BEGIN
    DECLARE @Result DataType

    -- Logic here
    SELECT @Result = Value
    FROM dbo.SourceTable WITH (NOLOCK)
    WHERE Condition = @Param1

    RETURN @Result
END
GO
```

---

## Nested Function Template

Use when function is called by other functions/SPs and should not be called directly by executors.

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="1"></info>*/
CREATE FUNCTION [dbo].[Aff_f_HelperFunctionName]
(
    @Param1 DataType
)
RETURNS TABLE
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Helper function - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize Function [RedmineID: #XXXXXX]

    Notes:
        - isNested="1": This function is called by other SPs/functions
        - Do not call directly from application layer
*/
RETURN
    SELECT
        Column1,
        Column2
    FROM dbo.SourceTable WITH (NOLOCK)
    WHERE Condition = @Param1
GO
```

---

## Common Function Patterns

### Exchange Rate Lookup
```sql
CREATE FUNCTION [dbo].[Aff_f_ExchangeRate_Sel]
(
    @ExchangeDate SMALLDATETIME,
    @ExchangeId INT,
    @BaseCurrency INT
)
RETURNS TABLE
AS
RETURN
    SELECT
        e.ExchangeDate,
        e.ExchangeId,
        e.Code,
        CASE @BaseCurrency
            WHEN  2 THEN e.MYR
            WHEN  3 THEN e.USD
            WHEN 51 THEN e.VND / 1000.0
            WHEN 15 THEN e.IDR / 1000.0
            ELSE 1
        END AS Rate
    FROM dbo.ExchangeOanda e WITH (NOLOCK)
    WHERE e.ExchangeDate = EOMONTH(@ExchangeDate)
        AND e.ExchangeId = @ExchangeId
GO
```

### Settings Lookup
```sql
CREATE FUNCTION [dbo].[Aff_f_GetSetting]
(
    @SName VARCHAR(50)
)
RETURNS VARCHAR(200)
AS
BEGIN
    DECLARE @SValue VARCHAR(200) = ''
    SELECT @SValue = SValue 
    FROM dbo.SystemSettings WITH (NOLOCK) 
    WHERE SName = @SName
    
    RETURN @SValue
END
GO
```

### String Split (Legacy - use STRING_SPLIT when possible)
```sql
CREATE FUNCTION [dbo].[Aff_f_StringSplit]
(
    @String NVARCHAR(MAX),
    @Delimiter CHAR(1)
)
RETURNS @Result TABLE (Value NVARCHAR(MAX))
AS
BEGIN
    -- String split logic
    RETURN
END
GO
```

---

## Quick Reference

### Naming Pattern
```
Aff_f_[FunctionPurpose]
Aff_f_ExchangeRate_Sel
Aff_f_GetSetting
Aff_f_StringSplit
```

### When to Use isNested="1"
- Function called by other SPs/functions
- Not meant for direct application layer calls
- Internal helper/utility functions

### Required Elements
- ✅ Proper function type declaration (TABLE vs scalar)
- ✅ NOLOCK on all table reads
- ✅ Clear parameter documentation
- ✅ Usage examples in comments

---

**Last Updated**: 2025-11-19  
**Owner**: DBA Team
