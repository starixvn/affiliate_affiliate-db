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
7. [Transaction Pattern](#7-transaction)
8. [Dynamic SQL](#8-dynamic-sql)
9. [Performance Optimization](#9-performance)

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

## 5.1 Batch Update/Delete (Large Datasets)

```sql
-- Pattern: Process large UPDATE/DELETE in batches using a temp table
-- 1) Create temp table with identity PK
-- 2) Populate with the rows (deterministic ordering)
-- 3) Loop with threshold-sized batches and perform set-based updates/deletes

CREATE TABLE #Result (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    KeyCol INT NOT NULL,
    SomeValue VARCHAR(200) NULL
)

-- Populate deterministic set
INSERT INTO #Result (KeyCol, SomeValue)
SELECT t.KeyCol, t.SomeValue
FROM dbo.SourceTable t WITH (NOLOCK)
WHERE /* your filter */ 1=1
ORDER BY t.KeyCol -- ensure deterministic order

-- Batch control variables
DECLARE @StartRow INT,
        @StopRow INT,
        @MaxRow INT,
        @Threshold INT = 20000; -- adjust as needed

SELECT @MaxRow = (SELECT MAX(Id) FROM #Result)
IF @MaxRow IS NULL
BEGIN
    DROP TABLE #Result
    RETURN
END

IF @Threshold >= @MaxRow
    SET @Threshold = @MaxRow

SET @StartRow = 1
SET @StopRow = @Threshold

WHILE (@StartRow <= @MaxRow)
BEGIN
    -- Example: set-based UPDATE using UPDLOCK, ROWLOCK
    UPDATE t
    SET t.Status = 1,
        t.UpdatedDate = GETDATE()
    FROM dbo.TargetTable t WITH (UPDLOCK, ROWLOCK)
    INNER JOIN #Result r ON r.KeyCol = t.KeyCol
    WHERE r.Id BETWEEN @StartRow AND @StopRow

    -- Optional: check progress
    DECLARE @DebugMsg VARCHAR(200) = CONVERT(VARCHAR(50), GETDATE(), 121) + ' Processed ' + CAST(@StartRow AS VARCHAR) + '-' + CAST(@StopRow AS VARCHAR)
    RAISERROR(@DebugMsg, 0, 1) WITH NOWAIT

    IF @StopRow = @MaxRow BREAK

    SET @StartRow = @StopRow + 1
    SET @StopRow = @StopRow + @Threshold
    IF @StopRow >= @MaxRow SET @StopRow = @MaxRow
END

DROP TABLE #Result
```


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

## 7. Transaction Pattern

```sql
-- Error handling with TRY-CATCH
-- Manual rollback = You must write code to undo changes if error occurs
BEGIN TRY

    -- Save current state before changes
    DECLARE @OldStatusId INT, @OldBalance MONEY
    SELECT @OldStatusId = StatusId FROM dbo.MemberCPA WITH (NOLOCK) WHERE MemberCPA_ID = @MemberCPA_ID
    SELECT @OldBalance = Balance FROM dbo.AffInfo WITH (NOLOCK) WHERE AffId = @AffId

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
    
    DECLARE @TransId INT = SCOPE_IDENTITY()

    -- Step 3: Update affiliate balance
    UPDATE ai
    SET ai.Balance = ai.Balance + @CPAAmount,
        ai.UpdatedDate = GETDATE()
    FROM dbo.AffInfo ai WITH (UPDLOCK, ROWLOCK)
    WHERE ai.AffId = @AffId

    SELECT 1 AS Success

END TRY
BEGIN CATCH

    -- Manual rollback: Undo all changes manually
    
    -- Undo Step 3: Restore balance
    UPDATE ai
    SET ai.Balance = @OldBalance
    FROM dbo.AffInfo ai WITH (UPDLOCK, ROWLOCK)
    WHERE ai.AffId = @AffId
    
    -- Undo Step 2: Delete transaction
    DELETE FROM dbo.AffTrans WITH (ROWLOCK)
    WHERE TransId = @TransId
    
    -- Undo Step 1: Restore status
    UPDATE mc
    SET mc.StatusId = @OldStatusId
    FROM dbo.MemberCPA mc WITH (UPDLOCK, ROWLOCK)
    WHERE mc.MemberCPA_ID = @MemberCPA_ID

    -- Log error
    DECLARE @ErrorMsg NVARCHAR(4000) = ERROR_MESSAGE()
    INSERT INTO dbo.ErrorLog (ErrorMessage, ErrorDate)
    VALUES (@ErrorMsg, GETDATE())

    SELECT 0 AS Success, @ErrorMsg AS ErrorMessage

END CATCH
```

---

## 8. Dynamic SQL

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

## 9. Performance Optimization

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
