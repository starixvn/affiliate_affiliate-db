/* Extended table profiling: row counts, size (MB), index count, structure type, create/modify dates.
   Use this snapshot to populate `.context/schema-summary.md` and identify partition/archive candidates.
   NOTE: Filters exclude temp/test artifacts. Adjust as needed. */

SET NOCOUNT ON;

WITH base AS (
    SELECT t.object_id, t.name, t.create_date, t.modify_date
    FROM sys.tables t
    WHERE t.name NOT LIKE '%Sally%'
      AND t.name NOT LIKE '%lewis%'
      AND t.name NOT LIKE '%PROD%'
      AND t.name NOT LIKE '%PRO%'
      AND t.name NOT LIKE '%instance%'
      AND t.name NOT LIKE '%intance%'
      AND t.name NOT LIKE '%tmp%'
      AND t.name NOT LIKE '%_2%'
      AND t.name NOT LIKE '%5%'
      AND t.name NOT LIKE '%7%'
      AND t.name NOT LIKE '%6%'
      AND t.name NOT LIKE '%LandingPage_%'
      AND t.name NOT LIKE '%_Feb18%'
)
SELECT TOP 1000
    b.name                        AS table_name,
    SUM(p.rows)                   AS row_count,
    CAST(SUM(a.total_pages)*8/1024.0 AS DECIMAL(18,2)) AS size_mb,
    CASE WHEN MIN(CASE WHEN i.index_id = 1 THEN 1 END) = 1 THEN 'CLUSTERED' ELSE 'HEAP' END AS structure_type,
    ISNULL(idx.index_count,0)     AS index_count,
    b.create_date,
    b.modify_date
FROM base b
JOIN sys.partitions p ON p.object_id = b.object_id AND p.index_id IN (0,1)
JOIN sys.allocation_units a ON a.container_id = p.partition_id
OUTER APPLY (
    SELECT COUNT(*) AS index_count
    FROM sys.indexes i2
    WHERE i2.object_id = b.object_id
      AND i2.index_id > 0
) idx
LEFT JOIN sys.indexes i ON i.object_id = b.object_id AND i.index_id = 1
GROUP BY b.name, b.create_date, b.modify_date, idx.index_count
ORDER BY row_count DESC;

/* Suggested follow-ups:
   - Capture output to markdown snapshot.
   - Identify tables with size_mb > X and low dependency references for archival.
   - Join with sys.dm_db_index_usage_stats for read/write pattern (separate script).
*/
