---
description: "SQL Coding Standards - Naming, Formatting, Locking, Patterns"
applyTo: "**/*.sql"
---

# SQL Server Coding Standards (12B Affiliate DB)

## 🏷️ Naming Conventions

See the dedicated naming guide: `.context/common/sql-naming.md` for naming patterns, layer prefixes, action suffixes, and examples. This file centralizes naming so templates and environment docs can reference a single source of truth.

## 📝 Templates

**Use copy-paste ready templates** from dedicated template files:

- **Stored Procedures**: See [`sql-template-sp.md`](../../.context/common/sql-template-sp.md) - Admin/User/API/Task layer templates
- **Functions**: See [`sql-template-function.md`](../../.context/common/sql-template-function.md) - Table-valued, scalar, and nested functions
- **Scripts**: See [`sql-template-script.md`](../../.context/common/sql-template-script.md) - DDL/DML migration scripts
- **Environment**: See [`sql-environment.md`](../../.context/common/sql-environment.md) - Server aliases and executor accounts

### Quick Header Reference

```sql
-- Stored Procedure (User layer)
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="0" isNested="0"></info>*/

-- Function (Table-valued)
/*<info serverAlias="DBAFF12B-Affiliate_12B" executers="wsv_afinet,wsv_afinetv" isFunction="1" isNested="0"></info>*/

-- Script (DDL/DML)
/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
```

**Note**: All serverAlias values and executor accounts are defined in [`sql-environment.md`](../../.context/common/sql-environment.md)

## 🔒 Locking Hints (CRITICAL)

### SELECT Queries
```sql
-- Always use NOLOCK for read operations
-- Both WITH (NOLOCK) and WITH(NOLOCK) are acceptable (prefer spacing for readability)
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
-- Use ROWLOCK for deletes (RARE - prefer soft delete via Status update)
DELETE t
FROM dbo.AffiliateInfo t WITH (ROWLOCK)
WHERE t.AffId = @AffId

-- Preferred: Soft delete pattern
UPDATE t
SET t.Status = 'Deleted',
    t.UpdatedDate = GETDATE()
FROM dbo.AffiliateInfo t WITH (UPDLOCK, ROWLOCK)
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
-- ALWAYS use CREATE TABLE (never SELECT INTO)
CREATE TABLE #CPASummary (
    AffId INT NOT NULL,
    TotalCPA MONEY,
    PlayerCount INT
)

-- Add index if temp table > 100 rows and used in JOINs
CREATE NONCLUSTERED INDEX IX_CPASummary_AffId ON #CPASummary (AffId)

-- Populate with INSERT INTO SELECT
INSERT INTO #CPASummary (AffId, TotalCPA, PlayerCount)
SELECT AffId, SUM(Amount), COUNT(1)
FROM dbo.MemberCPA WITH (NOLOCK)
GROUP BY AffId

-- Use temp table
SELECT cs.AffId, cs.TotalCPA
FROM #CPASummary cs
INNER JOIN dbo.AffInfo ai WITH (NOLOCK) ON ai.AffId = cs.AffId

-- Always clean up (optional - auto-dropped at session end)
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

### Batch Processing Large Datasets

When performing large UPDATE/DELETE operations, prefer batching to avoid long-running transactions and excessive log growth. Use a temporary table with an `IDENTITY` primary key for deterministic paging, then process rows in chunks.

Guidelines:
- Create temp table with an `IDENTITY` primary key (do not use `SELECT INTO`).
- Populate with `INSERT INTO #tmp (...) SELECT ... ORDER BY <unique_key>` to ensure deterministic ordering.
- Use `@Threshold` to control batch size and iterate with a `WHILE` loop using `Id BETWEEN @Start AND @Stop`.
- Always `DROP TABLE` the temp table at the end.

Refer to `sql-examples.instructions.md` for a copy-paste ready batch update/delete example.

## 🎯 Common Patterns (See sql-examples.instructions.md for full code)

### Must-Know Patterns
- **Pagination**: Use `ROW_NUMBER()` with temp table and `BETWEEN`
- **Temp Tables**: Add indexes if used in JOINs
- **String Split**: Use `STRING_SPLIT()` or `Aff_f_StringSplit()`
- **Transactions**: Use TRY-CATCH with manual rollback (write code to undo changes in CATCH block)
- **Dynamic SQL**: Use `sp_executesql` with parameters (prevent injection)
- **Currency Scaling**: VND/IDR divided by 1000: `/ CASE WHEN e.Code IN ('VND', 'IDR') THEN 1000.0 ELSE 1.0 END`
- **Timezone**: GMT+0 to GMT+8: `DATEADD(HOUR, 8, utcDateTime)`
- **XML Parameters**: Use for complex multi-row inputs (see Deal Ins/Upd SPs for examples)

### Critical Rules
- **Conditional WHERE**: Use `(@Param = '' OR column = @Param)` pattern
- **Sargable Predicates**: Never use functions on indexed columns
- **EXISTS vs COUNT**: Use `EXISTS` for existence checks (faster)

## ⚠️ Anti-Patterns (Common Mistakes)

**❌ DON'T**:
1. Skip NOLOCK on SELECT → May cause blocking
2. Use `SELECT *` → Specify columns explicitly
3. Use `SELECT INTO #TempTable` → Use `CREATE TABLE` then `INSERT INTO`
4. Omit ORDER BY direction → Always use ASC/DESC
5. Use functions on indexed columns → Not sargable (e.g., `YEAR(Date)`)
6. Use cursors for bulk updates → Use set-based operations

**✅ See `sql-examples.instructions.md` for correct patterns with full code**

## 🔍 Environment Reference

**Server aliases, executors, and database mappings** → See [`sql-environment.md`](../../.context/common/sql-environment.md)

Quick reference:
- `DBAFF12B-Affiliate_12B` - 12B affiliate database
- `DBAFFN8B-Affiliate_N8B` - N88 affiliate database  
- `DBAFFYASHBET-Affiliate_YashBet` - YashBet affiliate database

---
**Last Updated**: 2025-11-18 (Reviewed: Added function headers, clarified layers, documented common patterns)
**Owner**: DBA Team
