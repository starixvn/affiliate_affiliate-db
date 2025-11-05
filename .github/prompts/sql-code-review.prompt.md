---
mode: 'agent'
tools: ['changes', 'codebase', 'editFiles', 'problems', 'execute_sql']
description: 'Universal SQL code review assistant that performs comprehensive security, maintainability, and code quality analysis across all SQL databases (MySQL, PostgreSQL, SQL Server, Oracle). Focuses on SQL injection prevention, access control, code standards, and anti-pattern detection. Complements SQL optimization prompt for complete development coverage.'
---

# SQL Code Review (Enhanced Advanced Edition)

Version: 2.0  
Purpose: High-fidelity, automated, multi-dimensional SQL Server (extensible to other RDBMS) review prompt with advanced analysis layers (performance, security, reliability, scalability, governance, maintainability).  
Supports: Stored Procedures, Functions, Views, Ad‑hoc Queries, Migration Scripts, Multi-Statement Batches.  

If model capability >= next-gen (e.g., GPT-5 or equivalent), enable "Advanced Depth Mode" features flagged below; otherwise gracefully degrade.

Perform a thorough SQL code review of ${selection} (or entire project if no selection) focusing on security, performance, maintainability, and database best practices. Automatically fetch all necessary information using the `execute_sql` tool and perform a comprehensive review without requiring user input.

## 🔄 Fully Automated Analysis Workflow

When a stored procedure name or SQL query is provided:
1. **Fetch Stored Procedure or Query Details**:
   - If a stored procedure name is provided, retrieve its code using:
     ```sql
     SELECT OBJECT_DEFINITION(OBJECT_ID('${procedure_name}')) AS SourceCode
     WHERE OBJECT_ID('${procedure_name}') IS NOT NULL;
     ```
   - If a SQL query is provided, analyze it directly.

2. **Identify Dependencies**:
   - Parse the code to identify all referenced tables, views, and nested stored procedures or functions.

3. **Fetch Schema Details**:
   - For each referenced table, fetch its schema using:
     ```sql
     SELECT COLUMN_NAME, DATA_TYPE, IS_NULLABLE, COLUMN_DEFAULT
     FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_NAME = 'YourTableName';
     ```

4. **Fetch Index Details**:
   - For each referenced table, fetch its index details using:
     ```sql
     SELECT
         i.name AS IndexName,
         i.type_desc AS IndexType,
         c.name AS ColumnName,
         ic.key_ordinal AS ColumnOrder,
         i.is_unique AS IsUnique,
         i.is_primary_key AS IsPrimaryKey
     FROM
         sys.indexes i
     INNER JOIN
         sys.index_columns ic ON i.object_id = ic.object_id AND i.index_id = ic.index_id
     INNER JOIN
         sys.columns c ON ic.object_id = c.object_id AND ic.column_id = c.column_id
     WHERE
         i.object_id = OBJECT_ID('YourTableName');
     ```

5. **Analyze Index Usage**:
   - Cross-check the fetched index details with the query's `WHERE`, `JOIN`, and `ORDER BY` clauses.
   - Determine if existing indexes are being utilized effectively.
   - Highlight columns that lack indexing and recommend appropriate indexes.

6. **Generate Execution Plan**:
   - **In SSMS or tools supporting `GO`:**
     ```sql
     SET SHOWPLAN_XML ON;
     GO
     EXEC YourStoredProcedureName; -- or your query
     GO
     SET SHOWPLAN_XML OFF;
     GO
     ```
   - **In ODBC or programmatic environments:**
     Send each statement as a separate batch:
     1. `SET SHOWPLAN_XML ON;`
     2. Your query or `EXEC YourStoredProcedureName;`
     3. `SET SHOWPLAN_XML OFF;`
   This ensures compatibility with both SSMS and ODBC.

7. **Analyze and Recommend**:
   - Use the fetched schema, index details, and execution plan to:
     - Validate index usage and recommend missing indexes.
     - Identify and fix performance bottlenecks (e.g., table scans, high-cost operations).
     - Ensure proper use of data types, constraints, and joins.

8. **Recursive Analysis**:
   - If nested stored procedures or functions are identified, repeat the above steps for each dependency.

9. **Fallback Handling**:

10. **(Optional) Collect Runtime Diagnostics** (if sandbox execution permitted):
   - Capture SET STATISTICS IO, TIME output.
   - Compare estimated vs actual rows; flag divergence ratio > 4x.
   - Detect spills: worktable / workfile indications in execution plan.
   - Identify memory grant warnings & excessive grant vs usage.

11. **Multi-Statement Ordering Analysis**:
   - Determine if earlier statements can be refactored to CTEs / temp tables / table variables.
   - Detect unnecessary cursor usage; propose set-based alternative.

12. **Parameter Sniffing Risk Assessment**:
   - Look for parameter-sensitive predicates on highly skewed columns.
   - Recommend OPTIMIZE FOR, OPTION (RECOMPILE), or plan-stabilizing patterns when justified.

13. **Concurrency & Locking Model Check**:
   - Infer expected isolation level; detect hints (WITH (NOLOCK), READUNCOMMITTED) misuse.
   - Assess potential escalation risk (large range scans without covering indexes).
   - Suggest batching or pagination for large modifications.

14. **Change Impact Classification** (CRUD taxonomy + risk score):
   - Classify query as: Read / Write / Mixed / DDL / Security-affecting.
   - Compute risk score (see Advanced Metrics section).
   - If any required information cannot be fetched (e.g., due to missing permissions), provide clear fallback recommendations without asking for user intervention.

## 🔒 Security Analysis

### SQL Injection Prevention
```sql
-- ❌ CRITICAL: SQL Injection vulnerability
query = "SELECT * FROM users WHERE id = " + userInput;
query = f"DELETE FROM orders WHERE user_id = {user_id}";

-- ✅ SECURE: Parameterized queries
-- PostgreSQL/MySQL
PREPARE stmt FROM 'SELECT * FROM users WHERE id = ?';
EXECUTE stmt USING @user_id;

-- SQL Server
EXEC sp_executesql N'SELECT * FROM users WHERE id = @id', N'@id INT', @id = @user_id;
```

### Access Control & Permissions
- **Principle of Least Privilege**: Grant minimum required permissions
- **Role-Based Access**: Use database roles instead of direct user permissions
- **Schema Security**: Proper schema ownership and access controls
- **Function/Procedure Security**: Review DEFINER vs INVOKER rights

### Data Protection
### Additional Security (Advanced Depth Mode)
- Identify dynamic SQL concatenation patterns (EXEC(@sql)) and classify sanitization safety.
- Detect exposure of PII-like columns (Email, Phone, NationalID) without masking.
- Flag use of deprecated encryption / hash algorithms (e.g., SHA1) and suggest stronger (SHA2_256 / Always Encrypted / TDE / AEAD). 
- Check for potential privilege escalation via EXECUTE AS or ownership chaining edge cases.
- Evaluate RLS (Row Level Security) expectation: warn if business rules imply tenant isolation but no predicate filtering present.
- **Sensitive Data Exposure**: Avoid SELECT * on tables with sensitive columns
- **Audit Logging**: Ensure sensitive operations are logged
- **Data Masking**: Use views or functions to mask sensitive data
- **Encryption**: Verify encrypted storage for sensitive data

## ⚡ Performance Optimization

### Query Structure Analysis
```sql
-- ❌ BAD: Inefficient query patterns
SELECT DISTINCT u.* 
FROM users u, orders o, products p
WHERE u.id = o.user_id 
AND o.product_id = p.id
AND YEAR(o.order_date) = 2024;

-- ✅ GOOD: Optimized structure
SELECT u.id, u.name, u.email
FROM users u
INNER JOIN orders o ON u.id = o.user_id
WHERE o.order_date >= '2024-01-01' 
AND o.order_date < '2025-01-01';
```

### Index Strategy Review
Additional Index Considerations:
- Evaluate INCLUDE column opportunities vs widening key.
- Recommend filtered index (WHERE IsActive=1) when selectivity >> total cardinality.
- Suggest columnstore for large analytic / aggregation heavy tables.
- Detect wasted duplicate similar prefixes (idx_A_B_C vs idx_A_B).
- **Missing Indexes**: Automatically identify columns that need indexing based on query patterns.
- **Over-Indexing**: Detect unused or redundant indexes.
- **Composite Indexes**: Recommend multi-column indexes for complex queries.
- **Index Maintenance**: Check for fragmented or outdated indexes.

### Execution Plan Analysis
Advanced Plan Heuristics:
- Cardinality Misestimation: Flag operators with Actual vs Estimate rows variance > 10x.
- Residual Predicate Warnings (seek + residual predicate indicates possible missing composite key portion).
- Parallelism: Check CXPACKET / skew hints (if info provided) and recommend MAXDOP hint only when truly beneficial.
- Memory Grants: Identify excessive memory grant vs used (< 25% consumed) or spill risk (hash / sort spill).
- Tempdb Pressure Patterns: Large sort/hash + spool usage.
- **Table Scans**: Identify and recommend fixes for full table scans.
- **Expensive Operations**: Highlight high-cost operations and suggest optimizations.
- **Index Usage**: Ensure indexes are being used effectively in the query.

### Join Optimization
- **Join Types**: Verify appropriate join types (INNER vs LEFT vs EXISTS).
- **Join Order**: Optimize for smaller result sets first.
- **Cartesian Products**: Identify and fix missing join conditions.
- **Subquery vs JOIN**: Choose the most efficient approach.

### Aggregate and Window Functions
```sql
-- ❌ BAD: Inefficient aggregation
SELECT user_id, 
       (SELECT COUNT(*) FROM orders o2 WHERE o2.user_id = o1.user_id) as order_count
FROM orders o1
GROUP BY user_id;

-- ✅ GOOD: Efficient aggregation
SELECT user_id, COUNT(*) as order_count
FROM orders
GROUP BY user_id;
```

## 🛠️ Code Quality & Maintainability

### SQL Style & Formatting
```sql
-- ❌ BAD: Poor formatting and style
select u.id,u.name,o.total from users u left join orders o on u.id=o.user_id where u.status='active' and o.order_date>='2024-01-01';

-- ✅ GOOD: Clean, readable formatting
SELECT u.id,
       u.name,
       o.total
FROM users u
LEFT JOIN orders o ON u.id = o.user_id
WHERE u.status = 'active'
  AND o.order_date >= '2024-01-01';
```

### Naming Conventions
- **Consistent Naming**: Tables, columns, constraints follow consistent patterns.
- **Descriptive Names**: Clear, meaningful names for database objects.
- **Reserved Words**: Avoid using database reserved words as identifiers.
- **Case Sensitivity**: Consistent case usage across schema.

### Schema Design Review
- **Normalization**: Appropriate normalization level (avoid over/under-normalization).
- **Data Types**: Optimal data type choices for storage and performance.
- **Constraints**: Proper use of PRIMARY KEY, FOREIGN KEY, CHECK, NOT NULL.
- **Default Values**: Appropriate default values for columns.

## 🗄️ Database-Specific Best Practices

### SQL Server
```sql
-- Use appropriate data types
CREATE TABLE products (
    id BIGINT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(255) NOT NULL,
   ### Additional Maintainability Checks
   - Excessive branching / nested IF depth > 4 → propose modularizing into helper SPs / functions.
   - Repeated literal values → suggest parameters / lookup tables.
   - Hard-coded business rules vs rule tables (commission tiers, FX windows).
   - Legacy pattern detection (old style JOIN syntax, implicit cross joins).
   - Use of SELECT INTO temp tables vs explicit CREATE + INSERT (control over schema).
   - Error Handling: Ensure TRY/CATCH + XACT_ABORT ON for multi-statement transactional logic.
   - Idempotency: For deployment / migration scripts, ensure IF EXISTS guards.
    price DECIMAL(10,2) NOT NULL,
    created_at DATETIME2 DEFAULT GETUTCDATE()

## 🧪 Testing & Validation
-- Verify referential integrity
SELECT o.user_id 
-- Check for data consistency
SELECT COUNT(*) as inconsistent_records

### Performance Testing
- **Regression Testing**: Ensure optimizations don't break functionality.

### N+1 Query Problem
```sql
for user in users:
-- ✅ GOOD: Single optimized query
SELECT u.*, o.*
FROM users u
LEFT JOIN orders o ON u.id = o.user_id;
```

### Overuse of DISTINCT
```sql
-- ❌ BAD: DISTINCT masking join issues
SELECT DISTINCT u.name 
FROM users u, orders o 
WHERE u.id = o.user_id;

-- ✅ GOOD: Proper join without DISTINCT
SELECT u.name
FROM users u
INNER JOIN orders o ON u.id = o.user_id
GROUP BY u.name;
```

### Function Misuse in WHERE Clauses
```sql
-- ❌ BAD: Functions prevent index usage
SELECT * FROM orders 
WHERE YEAR(order_date) = 2024;


## 📋 SQL Review Checklist
- [ ] No dynamic SQL construction with string concatenation.
- [ ] Sensitive data is properly protected.
   ## � QUICK REFERENCE CHECKLIST (Condensed)
   Security: Injection? Dynamic SQL sanitized? PII masked?  
   Performance: Scans? Missing index? Spills? Parameter sniffing?  
   Concurrency: Lock escalation risk? Isolation misuse?  
   Maintainability: Header? Modular? No SELECT *? Consistent naming?  
   Governance: Retention? Audit trail? Sensitive table unfiltered?  
   Reliability: Error handling? Idempotent migrations? Time zone safe?

   ---

   Retain original instructions below this line for backward compatibility.

- [ ] SQL injection attack vectors are eliminated.

### Performance
- [ ] Indexes exist for frequently queried columns.
- [ ] No unnecessary SELECT * statements.
- [ ] JOINs are optimized and use appropriate types.
- [ ] WHERE clauses are selective and use indexes.
- [ ] Subqueries are optimized or converted to JOINs.

### Code Quality
- [ ] Consistent naming conventions.
- [ ] Proper formatting and indentation.
- [ ] Meaningful comments for complex logic.
- [ ] Appropriate data types are used.
- [ ] Error handling is implemented.

### Schema Design
- [ ] Tables are properly normalized.
- [ ] Constraints enforce data integrity.
- [ ] Indexes support query patterns.
- [ ] Foreign key relationships are defined.
- [ ] Default values are appropriate.

## 🎯 Review Output Format

### Issue Template
```
## [PRIORITY] [CATEGORY]: [Brief Description]

**Location**: [Table/View/Procedure name and line number if applicable]
**Issue**: [Detailed explanation of the problem]
**Security Risk**: [If applicable - injection risk, data exposure, etc.]
**Performance Impact**: [Query cost, execution time impact]
**Recommendation**: [Specific fix with code example]

**Before**:
```sql
-- Problematic SQL
```

**After**:
```sql
-- Improved SQL
```

**Expected Improvement**: [Performance gain, security benefit]
```

### Summary Assessment
- **Security Score**: [1-10] - SQL injection protection, access controls.
- **Performance Score**: [1-10] - Query efficiency, index usage.
- **Maintainability Score**: [1-10] - Code quality, documentation.
- **Schema Quality Score**: [1-10] - Design patterns, normalization.

### Top 3 Priority Actions
1. **[Critical Security Fix]**: Address SQL injection vulnerabilities.
2. **[Performance Optimization]**: Add missing indexes or optimize queries.
3. **[Code Quality]**: Improve naming conventions and documentation.

Focus on providing actionable, database-agnostic recommendations while highlighting platform-specific optimizations and best practices.