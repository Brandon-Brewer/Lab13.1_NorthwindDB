/****** Script for SelectTopNRows command from SSMS  ******/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

SELECT TOP 1000 [LoanPriorityMovementID]
      ,[FullNameFirstLast]
      ,[OpsTeamLeader]
      ,[OpsTeamLeaderCommonID]
      ,[OpsDirector]
      ,[OpsDirectorCommonID]
	  ,lpmc.LoanPriorityListID
	  ,lpd.PriorityListName
	  ,lpd.InsertDtDW
      --,lpmc.CommonID
	  --,em.Birthday
	  --,em.Department
	  --,em.JobGroup
	  --,em.Jobtitle
   
  FROM [BILoan].[dbo].[LoanPriorityMovementFact_Current] lpmc
	INNER JOIN BILoan..LoanPriorityListDim lpd ON lpd.LoanPriorityListID = lpmc.LoanPriorityListID
	--INNER JOIN QLODS..EmployeeMaster em ON em.CommonID = lpmc.CommonID (NOLOCK)

  WHERE lpmc.CommonID <> 1
	AND lpd.PriorityListName LIKE '%HOI%'