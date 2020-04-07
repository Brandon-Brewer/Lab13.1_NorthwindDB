SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT
  em.CommonID
, em.FullNameFirstLast
, em.JobTitle
, [CurrentTier]				= CASE WHEN em.JobTitle LIKE '%Triple%' THEN 'Triple Crown'
								   WHEN em.JobTitle LIKE '%President%' THEN 'President''s Club'
								   WHEN em.JobTitle LIKE '%Executive%' THEN 'Executive'	
								   WHEN em.JobTitle LIKE '%Senior%' THEN 'Senior'
								   ELSE 'Specialist' END
, [CurrentTierID]			= CASE WHEN em.JobTitle LIKE '%Triple%' THEN 1
								   WHEN em.JobTitle LIKE '%President%' THEN 2
								   WHEN em.JobTitle LIKE '%Executive%' THEN 3
								   WHEN em.JobTitle LIKE '%Senior%' THEN 4
								   ELSE 5 END
, em.EmpStatus
, em.OpsTeamLeader
, em.OpsDirector
, em.OpsDVP
, [Specialty]				= CASE WHEN em.OpsDirectorCommonID = 1004841 THEN 'Purchase Hunt'
								   WHEN em.JobTitle LIKE '%Refinance Escalation%' THEN 'Refi Escalation'
								   WHEN em.JobTitle LIKE '%Purchase Escalation%' THEN 'Purchase Escalation'
								   WHEN em.JobTitle LIKE '%Purchase%' THEN 'Purchase Mainstream'
								   WHEN em.JobTitle LIKE '%Client Care%' THEN 'Refi Mainstream'
								   ELSE NULL END
INTO #bp
FROM QLODS.dbo.EmployeeMaster em WITH (NOLOCK)
WHERE em.JobTitle IS NOT NULL
	AND em.EmpStatus <> 'T'
ORDER BY em.CommonID



SELECT * FROM #bp WHERE #bp.Specialty IS NOT NULL ORDER BY #bp.CommonID