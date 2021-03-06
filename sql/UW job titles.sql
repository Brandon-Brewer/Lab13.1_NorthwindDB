/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT JobTitle
--  FROM [QLODS].[dbo].[EmployeeMaster]
--  WHERE Jobgroup = 'tm'
--		AND Company LIKE '%Quicken%'
--		AND (JobTitle LIKE '%UW%' 
--		OR JobTitle LIKE '%Underwrit%')
--		AND Jobgroup = 'tm'
--		AND Department = 173
--  GROUP BY JobTitle

  --SELECT JobTitle
  --FROM QLODS.dbo.EmployeeMaster em
  --WHERE em.SpecialtyGrpID = 526
  ----WHERE em.JobTitle LIKE '%associate%underwrit%'
  --GROUP BY JobTitle

  SELECT JobTitle
  FROM QLODS.dbo.EmployeeMaster em
  WHERE em.JobTitle LIKE '%Associate%' 
		AND (em.Division LIKE '%Underwr%' 
		OR em.Division LIKE '%UW%' 
		OR em.JobTitle LIKE '%Underwr%'
		OR em.JobTitle LIKE '%UW%')
  GROUP BY JobTitle
	      

  /***********************
  JOB TITLES
	Operations Specialist
	Income Specialist
	%qual%assur%
*****************************/