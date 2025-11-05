/*<info serverAlias="DBAFF12B-Affiliate_12B"></info>*/
/*
	Purpose: Extract stored procedure dependency map and produce Top-N referenced objects per procedure plus global frequency ranking.
	Usage:   Run ad-hoc to refresh context artifacts (dependency-graph.md, sp-catalog KeyDependencies column).
	Params:  @TopN INT = number of top dependencies to keep per procedure (default 10)
	Output Sets:
		1) ProcedureDependencies - Raw list of dependencies (one row per referenced object)
		2) ProcedureTopNDependencies - Top-N dependencies per procedure (ordered by frequency across all procedures then by name)
		3) GlobalDependencyFrequency - Objects ranked by total referencing procedures
	Notes:
		- Filters to only user stored procedures (type = 'P') in dbo schema by default.
		- Excludes system objects, temporary objects, and built-in functions.
		- Use this output to update KeyDependencies in sp-catalog.md.
	Revisions:
		- 20251107@Copilot: Initial creation for context automation [RedmineID: #NONE]
*/

DECLARE @TopN INT = 10; -- adjustable

/* ------------------------------
   Base: Procedure list
------------------------------ */
WITH ProcList AS (
    SELECT p.object_id, p.name AS ProcedureName, s.name AS SchemaName
    FROM sys.procedures p
    INNER JOIN sys.schemas s ON p.schema_id = s.schema_id
    WHERE p.is_ms_shipped = 0
      AND s.name = 'dbo'
), RawDeps AS (
    SELECT 
        pl.ProcedureName,
        pl.SchemaName,
        d.referenced_id,
        o.type_desc AS ReferencedTypeDesc,
        COALESCE(o.name, OBJECT_NAME(d.referenced_id)) AS ReferencedName
    FROM ProcList pl
    LEFT JOIN sys.sql_expression_dependencies d ON pl.object_id = d.referencing_id
    LEFT JOIN sys.objects o ON d.referenced_id = o.object_id
    WHERE (o.is_ms_shipped = 0 OR o.is_ms_shipped IS NULL)
      AND (o.type IN ('U','V','P','FN','TF','IF') OR o.type IS NULL) -- include tables/views/procs/functions
      AND (COALESCE(o.name, OBJECT_NAME(d.referenced_id)) NOT LIKE '#%')
), CleanDeps AS (
    SELECT 
        ProcedureName,
        ReferencedName,
        ReferencedTypeDesc,
        SchemaName,
        ReferencedCategory = CASE 
            WHEN ReferencedName LIKE 'Aff_Admin_%' THEN 'Admin'
            WHEN ReferencedName LIKE 'Aff_User_%' THEN 'User'
            WHEN ReferencedName LIKE 'Aff_Con_%' THEN 'Security'
            WHEN ReferencedName LIKE 'Aff_f_%' THEN 'Function'
            WHEN ReferencedName LIKE 'Task_Aff_%' THEN 'Task'
            WHEN ReferencedName LIKE 'Aff_API_%' THEN 'API'
            WHEN ReferencedTypeDesc LIKE '%VIEW%' THEN 'View'
            WHEN ReferencedTypeDesc LIKE '%TABLE%' THEN 'Table'
            ELSE 'Other'
        END
    FROM RawDeps
    WHERE ReferencedName IS NOT NULL
), GlobalFreq AS (
    SELECT ReferencedName, ReferencedCategory, ReferencedTypeDesc,
           ReferencingProcedures = COUNT(DISTINCT ProcedureName)
    FROM CleanDeps
    GROUP BY ReferencedName, ReferencedCategory, ReferencedTypeDesc
), RankedDeps AS (
    SELECT cd.ProcedureName, cd.ReferencedName, cd.ReferencedCategory, cd.ReferencedTypeDesc, gf.ReferencingProcedures,
           GlobalRank = ROW_NUMBER() OVER (ORDER BY gf.ReferencingProcedures DESC, cd.ReferencedName ASC)
    FROM CleanDeps cd
    INNER JOIN GlobalFreq gf ON cd.ReferencedName = gf.ReferencedName
), TopNPerProc AS (
    SELECT ProcedureName, ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures,
           ProcRank = ROW_NUMBER() OVER (PARTITION BY ProcedureName ORDER BY ReferencingProcedures DESC, ReferencedName ASC)
    FROM RankedDeps
)
SELECT ProcedureName, ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
INTO #ProcedureDependencies
FROM RankedDeps;

SELECT ProcedureName, ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
INTO #ProcedureTopNDependencies
FROM TopNPerProc
WHERE ProcRank <= @TopN;

SELECT ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
INTO #GlobalDependencyFrequency
FROM GlobalFreq
ORDER BY ReferencingProcedures DESC, ReferencedName ASC;

/* Result Sets */
SELECT ProcedureName, ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
FROM #ProcedureDependencies 
ORDER BY ProcedureName ASC, ReferencingProcedures DESC, ReferencedName ASC;

SELECT ProcedureName, ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
FROM #ProcedureTopNDependencies 
ORDER BY ProcedureName ASC, ReferencingProcedures DESC, ReferencedName ASC;

SELECT ReferencedName, ReferencedCategory, ReferencedTypeDesc, ReferencingProcedures
FROM #GlobalDependencyFrequency 
ORDER BY ReferencingProcedures DESC, ReferencedName ASC;

/* Cleanup */
DROP TABLE #ProcedureDependencies;
DROP TABLE #ProcedureTopNDependencies;
DROP TABLE #GlobalDependencyFrequency;
