/* Transform dependency query into DOT format (run client-side to assemble) */
-- Pseudocode idea: Use this inside a client tool to spool results to a file
SELECT '"' + OBJECT_SCHEMA_NAME(d.referencing_id)+'.'+OBJECT_NAME(d.referencing_id) + '" -> "' +
       OBJECT_SCHEMA_NAME(d.referenced_id)+'.'+OBJECT_NAME(d.referenced_id) + '";' AS edge
FROM sys.sql_expression_dependencies d
JOIN sys.objects o ON o.object_id = d.referencing_id
WHERE o.type IN ('P','V','FN','IF','TF');
