---
description: "SQL Coding Standards - Naming, Formatting, Locking, Patterns"
applyTo: "**/*.sql"
---

# SQL Server Coding Standards (12B Affiliate DB)

## 🏷️ Naming Conventions

### Stored Procedures
**Pattern**: `Aff_[Module]_[Entity]_[Action]`

**Module Prefixes**:
- `Aff_Admin_*` - Admin procedures (executor: `wsv_afinet`)
- `Aff_User_*` - User procedures (executors: `wsv_afinet,wsv_afinetv`)
- `Aff_f_*` - Helper functions (can be nested)
- `Task_Aff_*` - Scheduled jobs

**Action Suffixes**:
- `_Sel` - SELECT
- `_Ins` - INSERT
- `_Upd` - UPDATE
- `_Del` - DELETE

**Examples**:
```sql
Aff_Admin_Report_PlayerCPA_Sel
Aff_User_Overview_Summary_Sel
Aff_f_ExchangeRate_Sel
Task_Aff_CPAActivePeriod
```

## 📝 File Headers

### Stored Procedure Header
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/
CREATE PROCEDURE [dbo].[Aff_Module_Entity_Action]
    @Param1 DataType,
    @Param2 DataType = DefaultValue
AS
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Module] - [Entity] - [Business Purpose]

    Revisions:
        - YYYYMMDD@Developer: Initialize SP [RedmineID: #XXXXXX]
*/
BEGIN
    SET NOCOUNT ON
    
    -- Code here
END
GO
```

### Script File Header
```sql
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
    Created: YYYYMMDD@Developer
    DB: DBAFF12B-Affiliate_12B
    Task: [Detailed description]
    RedmineID: #XXXXXX
*/

USE Affiliate_12B
GO

-- DDL operations here
GO
```

## 🔒 Locking Hints (CRITICAL)

### SELECT Queries
```sql
-- Always use NOLOCK for read operations
SELECT a.AffId, a.Username
FROM dbo.AffiliateInfo a WITH (NOLOCK)
WHERE a.Status = 1
```

### UPDATE Statements
```sql
-- Use UPDLOCK + ROWLOCK for single/narrow updates
UPDATE t
SET t.Status = @NewStatus
FROM dbo.AffiliateInfo t WITH (UPDLOCK, ROWLOCK)
WHERE t.AffId = @AffId
```

### DELETE Statements
```sql
-- Use ROWLOCK for deletes
DELETE t
FROM dbo.AffiliateInfo t WITH (ROWLOCK)
WHERE t.AffId = @AffId
```

## 📐 Formatting Rules

### Indentation & Keywords
```sql
-- 4 spaces (no tabs)
-- SQL keywords: UPPERCASE
-- Table aliases: lowercase
-- Align related keywords vertically

SELECT  a.AffId,
        a.Username,
        cg.GroupName
FROM    dbo.AffInfo a WITH (NOLOCK)
        INNER JOIN dbo.CommGroup cg WITH (NOLOCK) ON cg.GroupId = a.GroupId
WHERE   a.Status = 1
        AND a.IsClosed = 0
ORDER BY a.Username ASC;
```

### Required Practices
- ✅ **Always** start with `SET NOCOUNT ON` after `BEGIN`
- ✅ **Never** use `SELECT *` - list columns explicitly
- ✅ **Always** use schema prefix: `dbo.TableName`
- ✅ **Always** specify `ASC`/`DESC` in `ORDER BY`
- ✅ **Always** use `TOP (n)` with deterministic `ORDER BY`

## 🗄️ Temporary Tables

### Creation Pattern
```sql
-- Use single-hash for temp tables
CREATE TABLE #CPASummary (
    AffId INT NOT NULL,
    TotalCPA MONEY,
    PlayerCount INT
)

-- Add index if temp table > 100 rows and used in JOINs
CREATE NONCLUSTERED INDEX IX_CPASummary_AffId ON #CPASummary (AffId)

-- Use temp table
SELECT cs.AffId, cs.TotalCPA
FROM #CPASummary cs
INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = cs.AffId

-- Always clean up
DROP TABLE #CPASummary
```

### Table Variables (Small Data Only)
```sql
-- Use for < 100 rows only
DECLARE @SmallSet TABLE (
    Id INT PRIMARY KEY,
    Value VARCHAR(50)
)

INSERT INTO @SmallSet VALUES (1, 'Test')
```

## 🎯 Common Patterns (See sql-examples.instructions.md for full code)

### Must-Know Patterns
- **Pagination**: Use `ROW_NUMBER()` with temp table and `BETWEEN`
- **Temp Tables**: Add indexes if used in JOINs
- **String Split**: Use `STRING_SPLIT()` or `Aff_f_StringSplit()`
- **Transactions**: Use TRY-CATCH with manual ROLLBACK
- **Dynamic SQL**: Use `sp_executesql` with parameters (prevent injection)

### Critical Rules
- **Conditional WHERE**: Use `(@Param = '' OR column = @Param)` pattern
- **Sargable Predicates**: Never use functions on indexed columns
- **EXISTS vs COUNT**: Use `EXISTS` for existence checks (faster)

## ⚠️ Anti-Patterns (Common Mistakes)

**❌ DON'T**:
1. Skip NOLOCK on SELECT → May cause blocking
2. Use `SELECT *` → Specify columns explicitly
3. Omit ORDER BY direction → Always use ASC/DESC
4. Use functions on indexed columns → Not sargable (e.g., `YEAR(Date)`)
5. Use cursors for bulk updates → Use set-based operations

**✅ See `sql-examples.instructions.md` for correct patterns with full code**

## 🔍 Server Alias Reference

| Alias | Database | Environment |
|-------|----------|-------------|
| **DBAFF12B** | Affiliate_12B | TESTDB053 (local) / DR_DB05HA2G1L (prod) |
| DBAFFN8B | Affiliate_N8B | Same servers |
| DB12B | bodb_12B | Same servers |

**Always use alias format**: `DBAFF12B-Affiliate_12B`

---
**Last Updated**: 2025-11-10
**Owner**: DBA Team
