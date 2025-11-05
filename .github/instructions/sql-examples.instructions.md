---
description: "SQL Pattern Examples - Copy-paste ready code snippets"
applyTo: "**/*.sql"
---

# SQL Pattern Examples

Quick reference for common SQL patterns in 12B Affiliate DB. Copy-paste ready code.

---

## 📋 Pattern Index

1. [Simple SELECT with NOLOCK](#1-simple-select)
2. [Paginated List](#2-paginated-list)
3. [UPDATE with Locking](#3-update-with-lock)
4. [DELETE with Locking](#4-delete-with-lock)
5. [Temp Table Pattern](#5-temp-table)
6. [String Split Pattern](#6-string-split)
7. [CPA Calculation](#7-cpa-calculation)
8. [Transaction Pattern](#8-transaction)
9. [Dynamic SQL](#9-dynamic-sql)
10. [Performance Optimization](#10-performance)

---

## 1. Simple SELECT

```sql
-- Basic SELECT with proper locking and formatting
SELECT 
    a.AffId,
    a.Username,
    a.Email,
    a.Status,
    a.CreatedDate
FROM dbo.AffInfo a WITH (NOLOCK)
WHERE a.Status = 1
  AND a.CreatedDate >= @FromDate
  AND a.CreatedDate < @ToDate
ORDER BY a.Username ASC
```

---

## 2. Paginated List

```sql
-- Pagination pattern using ROW_NUMBER and temp table
DECLARE @PageIndex INT = 1
DECLARE @PageSize INT = 20
DECLARE @IsExportExcel BIT = 0
DECLARE @NRows INT

-- Build temp table with ROW_NUMBER
CREATE TABLE #data (
    Rid INT,
    AffId INT,
    Username NVARCHAR(100),
    Email NVARCHAR(100),
    Status INT
)

INSERT INTO #data (Rid, AffId, Username, Email, Status)
SELECT 
    ROW_NUMBER() OVER(ORDER BY a.AffId DESC) AS Rid,
    a.AffId,
    a.Username,
    a.Email,
    a.Status
FROM dbo.AffInfo a WITH (NOLOCK)
WHERE a.Status = 1

-- Get total count
SELECT @NRows = COUNT(DISTINCT Rid) FROM #data;

-- Calculate row range
DECLARE @RowStart INT, @RowEnd INT;

IF @IsExportExcel = 0
BEGIN
    SELECT @RowStart = (@PageIndex - 1) * @PageSize + 1,
           @RowEnd = @RowStart + @PageSize - 1;
END
ELSE
BEGIN
    SELECT @RowStart = 1,
           @RowEnd = @NRows;
END

-- Get paged data
SELECT 
    d.Rid,
    d.AffId,
    d.Username,
    d.Email,
    d.Status
FROM #data d
WHERE d.Rid BETWEEN @RowStart AND @RowEnd;

DROP TABLE #data;
```

---

## 3. UPDATE with Lock

```sql
-- UPDATE with proper locking hints
UPDATE t
SET t.Status = @Status,
    t.UpdatedDate = GETDATE(),
    t.UpdatedBy = @AdminId
FROM dbo.AffInfo t WITH (UPDLOCK, ROWLOCK)
WHERE t.AffId = @AffId
  AND t.Status <> @Status  -- Only update if changed
```

---

## 4. DELETE with Lock

```sql
-- DELETE with proper locking (rare - usually soft delete)
DELETE FROM t
FROM dbo.AffiliateNote t WITH (ROWLOCK)
WHERE t.NoteId = @NoteId
  AND t.AffId = @AffId
```

---

## 5. Temp Table

```sql
-- Temp table for complex calculations
CREATE TABLE #TempResults (
    AffId INT NOT NULL,
    TotalEarning MONEY NOT NULL,
    PlayerCount INT NOT NULL,
    PRIMARY KEY (AffId)
)

-- Populate temp table
INSERT INTO #TempResults (AffId, TotalEarning, PlayerCount)
SELECT 
    t.AffId,
    SUM(t.Amount) AS TotalEarning,
    COUNT(DISTINCT t.CustId) AS PlayerCount
FROM dbo.AffTrans t WITH (NOLOCK)
WHERE t.TransDate >= @FromDate
  AND t.TransDate < @ToDate
  AND t.TransType IN (201, 206)  -- Earning types
GROUP BY t.AffId

-- Use temp table in final query
SELECT 
    a.AffId,
    a.Username,
    tr.TotalEarning,
    tr.PlayerCount
FROM dbo.AffInfo a WITH (NOLOCK)
INNER JOIN #TempResults tr ON tr.AffId = a.AffId
ORDER BY tr.TotalEarning DESC

-- Cleanup (optional - auto-dropped at end of session)
DROP TABLE #TempResults
```

---

## 6. String Split

```sql
-- Split comma-separated string into table
DECLARE @ProductIds NVARCHAR(MAX) = '1,2,3,5,8'

-- Using built-in function (SQL Server 2016+)
SELECT value AS ProductId
FROM STRING_SPLIT(@ProductIds, ',')

-- Using custom function (older versions)
SELECT ProductId
FROM dbo.Aff_f_StringSplit(@ProductIds, ',')

-- Use in WHERE IN clause
SELECT 
    p.ProductId,
    p.ProductName
FROM dbo.Product p WITH (NOLOCK)
WHERE p.ProductId IN (SELECT value FROM STRING_SPLIT(@ProductIds, ','))
```

---

## 7. CPA Calculation

```sql
-- Count Eligibled CPAs (ready for payment)
SELECT 
    mc.AffId,
    COUNT(*) AS EligibleCount,
    SUM(mc.CPAAmount) AS TotalAmount
FROM dbo.MemberCPA mc WITH (NOLOCK)
WHERE mc.StatusId = 2  -- Eligibled
  AND mc.GroupId = @GroupId
  AND mc.IsAbnormal = 0
GROUP BY mc.AffId

-- Get CPA with tier breakdown
SELECT 
    mc.MemberCPA_ID,
    mc.CustId,
    mi.Username AS PlayerUsername,
    mc.StatusId,
    mc.CPAAmount,
    mct.TierId,
    mct.Turnover
FROM dbo.MemberCPA mc WITH (NOLOCK)
INNER JOIN dbo.MemberInfo mi WITH (NOLOCK) ON mi.CustId = mc.CustId
LEFT JOIN dbo.MemberCPATier mct WITH (NOLOCK) ON mct.MemberCPA_ID = mc.MemberCPA_ID
WHERE mc.AffId = @AffId
  AND mc.StatusId = 2
```

---

## 8. Transaction Pattern

```sql
-- Error handling with TRY-CATCH (NO explicit BEGIN TRAN)
-- SQL Server auto-starts implicit transaction for multi-step operations
BEGIN TRY

    -- Step 1: Update MemberCPA status
    UPDATE mc
    SET mc.StatusId = 3,  -- Settled
        mc.CPADate = GETDATE(),
        mc.UpdatedDate = GETDATE()
    FROM dbo.MemberCPA mc WITH (UPDLOCK, ROWLOCK)
    WHERE mc.MemberCPA_ID = @MemberCPA_ID
      AND mc.StatusId = 2  -- Only if Eligibled

    -- Step 2: Insert transaction record
    INSERT INTO dbo.AffTrans (
        AffId, TransType, Amount, CurrencyId, 
        RefId, TransDate, CreatedDate
    )
    VALUES (
        @AffId, 206, @CPAAmount, @CurrencyId,
        @MemberCPA_ID, GETDATE(), GETDATE()
    )

    -- Step 3: Update affiliate balance
    UPDATE ai
    SET ai.Balance = ai.Balance + @CPAAmount,
        ai.UpdatedDate = GETDATE()
    FROM dbo.AffInfo ai WITH (UPDLOCK, ROWLOCK)
    WHERE ai.AffId = @AffId

    SELECT 1 AS Success

END TRY
BEGIN CATCH

    -- Manual rollback if error occurs
    IF @@TRANCOUNT > 0
        ROLLBACK TRANSACTION

    -- Log error
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
    INSERT INTO dbo.ErrorLog (ErrorMessage, ErrorDate)
    VALUES (@ErrorMsg, GETDATE())

    SELECT 0 AS Success, @ErrorMsg AS ErrorMessage

END CATCH
```

---

## 9. Dynamic SQL

```sql
-- Dynamic SQL with proper parameterization (prevent SQL injection)
DECLARE @SQL NVARCHAR(MAX)
DECLARE @Params NVARCHAR(MAX)

SET @SQL = N'
    SELECT 
        a.AffId,
        a.Username,
        a.Status
    FROM dbo.AffInfo a WITH (NOLOCK)
    WHERE 1=1'

-- Add dynamic WHERE conditions
IF @StatusFilter IS NOT NULL
    SET @SQL = @SQL + N' AND a.Status = @Status'

IF @UsernameFilter IS NOT NULL
    SET @SQL = @SQL + N' AND a.Username LIKE @Username'

SET @SQL = @SQL + N' ORDER BY a.AffId DESC'

-- Define parameters
SET @Params = N'@Status INT, @Username NVARCHAR(50)'

-- Execute with parameters
EXEC sp_executesql 
    @SQL,
    @Params,
    @Status = @StatusFilter,
    @Username = @UsernameFilter
```

---

## 10. Performance Optimization

```sql
-- Pattern 1: Use EXISTS instead of COUNT
-- ❌ BAD
IF (SELECT COUNT(*) FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId) > 0
BEGIN
    -- Do something
END

-- ✅ GOOD
IF EXISTS (SELECT 1 FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId)
BEGIN
    -- Do something
END

-- Pattern 2: Avoid function on indexed column (non-SARGable)
-- ❌ BAD
SELECT * FROM dbo.AffInfo WITH (NOLOCK)
WHERE YEAR(CreatedDate) = 2024

-- ✅ GOOD
SELECT * FROM dbo.AffInfo WITH (NOLOCK)
WHERE CreatedDate >= '2024-01-01' AND CreatedDate < '2025-01-01'

-- Pattern 3: Use UNION ALL instead of UNION (if duplicates OK)
-- ❌ SLOWER (removes duplicates)
SELECT AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Status = 1
UNION
SELECT AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE IsFavorite = 1

-- ✅ FASTER (keeps duplicates)
SELECT AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE Status = 1
UNION ALL
SELECT AffId FROM dbo.AffInfo WITH (NOLOCK) WHERE IsFavorite = 1

-- Pattern 4: Avoid SELECT *
-- ❌ BAD
SELECT * FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

-- ✅ GOOD
SELECT 
    AffId,
    Username,
    Email,
    Status
FROM dbo.AffInfo WITH (NOLOCK)
WHERE AffId = @AffId
```

---

## 🎯 Anti-Patterns (AVOID)

1. **No NOLOCK on SELECT**:
   ```sql
   -- ❌ BAD - May cause blocking
   SELECT * FROM dbo.AffInfo WHERE AffId = @AffId
   
   -- ✅ GOOD
   SELECT * FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId
   ```

2. **Missing UPDLOCK on UPDATE**:
   ```sql
   -- ❌ BAD - May cause deadlock
   UPDATE dbo.AffInfo SET Status = 1 WHERE AffId = @AffId
   
   -- ✅ GOOD
   UPDATE a SET a.Status = 1
   FROM dbo.AffInfo a WITH (UPDLOCK, ROWLOCK)
   WHERE a.AffId = @AffId
   ```

3. **RBAR (Row-By-Agonizing-Row)**:
   ```sql
   -- ❌ BAD - Cursor loop
   DECLARE cur CURSOR FOR SELECT AffId FROM dbo.AffInfo
   OPEN cur
   FETCH NEXT FROM cur INTO @AffId
   WHILE @@FETCH_STATUS = 0
   BEGIN
       UPDATE dbo.AffInfo SET Status = 1 WHERE AffId = @AffId
       FETCH NEXT FROM cur INTO @AffId
   END
   
   -- ✅ GOOD - Set-based update
   UPDATE a SET a.Status = 1
   FROM dbo.AffInfo a WITH (UPDLOCK, ROWLOCK)
   WHERE a.Status = 0
   ```

---

**See Also**:
- `sql-standards.instructions.md` - Complete coding standards
- `cpa-module.instructions.md` - CPA-specific patterns
