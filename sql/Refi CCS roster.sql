/****************************************************************
Refi CCS Roster
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	em.*
	
FROM QLODS..EmployeeMaster em

WHERE 1=1
	AND em.JobTitle LIKE '%Client Care%'
	AND (em.OpsDirector LIKE '%Chandler'
		OR em.OpsDirector LIKE '%Gray'
		OR em.OpsDirector LIKE '%Andino'
		OR em.OpsDirector LIKE '%Meyers'
		OR em.OpsDirector LIKE '%Maynard'
		OR em.OpsDirector LIKE '%Caldwell')

ORDER BY em.FirstName

