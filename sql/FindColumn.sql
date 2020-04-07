USE QLODS
GO
SELECT t.*
FROM information_schema.columns t
WHERE t.COLUMN_NAME LIKE '%hotlist%' 
ORDER BY table_name;
