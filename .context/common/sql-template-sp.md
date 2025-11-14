# SQL Stored Procedure Template

**Usage**: Copy-paste template when creating new stored procedures.

**Environment Reference**: See `sql-environment.md` for serverAlias and executors.

---

## Admin Layer Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Admin_Module_Entity_Action]
    @Param1 DataType,
    @Param2 DataType = DefaultValue,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Module] - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]

    Parameter's Explanation:
        - @Param1: Description of param1
        - @Param2: Description of param2
*/
BEGIN
    SET NOCOUNT ON

    -- TODO: Validate Input
    IF @Param1 IS NULL
    BEGIN
        SELECT @ErrCode = 100, @ErrMsg = 'Param1 is required'
        RETURN
    END

    -- TODO: Main Logic

    -- Return success
    SELECT @ErrCode = 0, @ErrMsg = 'Success'
END
GO
```

---

## User Layer Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_User_Module_Entity_Action]
    @AffId INT,
    @Param1 DataType,
    @Param2 DataType = DefaultValue
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: User site - [Module] - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]

    Notes:
        - Add any important notes here (timezone, data sources, etc.)
*/
BEGIN
    SET NOCOUNT ON

    -- TODO: Validate Input

    -- TODO: Main Logic

    -- TODO: Return result
    SELECT
        Column1,
        Column2
    FROM dbo.TableName WITH (NOLOCK)
    WHERE Condition
END
GO
```

---

## API Layer Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_API_Entity_Action]
    @Param1 DataType,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: API - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]

    API Contract:
        - Endpoint: [URL]
        - Method: GET/POST
        - Response: JSON format
*/
BEGIN
    SET NOCOUNT ON

    -- TODO: Validate Input
    -- TODO: Main Logic
    -- TODO: Return JSON-compatible result
END
GO
```

---

## Task/Job Template

```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Task_Aff_JobName]
    @JobDate DATE = NULL,
    @ErrCode INT = 0 OUTPUT,
    @ErrMsg NVARCHAR(MAX) = '' OUTPUT
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: Scheduled job - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]

    Schedule:
        - Frequency: Daily/Weekly/Monthly
        - Run Time: HH:MM GMT+8
        - SQL Agent Job: [JobName]
*/
BEGIN
    SET NOCOUNT ON

    -- Default to yesterday if not provided
    IF @JobDate IS NULL
        SET @JobDate = CAST(DATEADD(DAY, -1, GETDATE()) AS DATE)

    -- TODO: Main Logic

    SELECT @ErrCode = 0, @ErrMsg = 'Success'
END
GO
```

---

## Quick Reference

### Naming Pattern
```
Aff_[Layer]_[Module]_[Entity]_[Action]
Aff_Admin_Report_PlayerCPA_Sel
Aff_User_Overview_Summary_Sel
Task_Aff_CPAActivePeriod
```

### Common Actions
- `_Sel` - SELECT queries
- `_Ins` - INSERT operations
- `_Upd` - UPDATE operations
- `_Del` - DELETE operations (rare - prefer soft delete)

### Required Elements
- ✅ SET NOCOUNT ON
- ✅ Input validation
- ✅ Explicit column lists (no SELECT *)
- ✅ NOLOCK hints on all reads
- ✅ Revision history with RedmineID

---

**Last Updated**: 2025-11-19  
**Owner**: DBA Team
