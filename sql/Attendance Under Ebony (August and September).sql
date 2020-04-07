/****************************************************************
This query attempts to find which team members (under Ebony) had 
perfect attendance for August and September.
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  tcd.TimeCodeDesignation
, tcd.TimeCode
, hf.WorkDateID
, hf.AdjustDateID
, hf.MinutesWorked
----, hf.TeamMemberID
----, em.CommonID
----, em.EmployeeDimID
, em.FullNameFirstLast
, em.JobTitle
, em.OpsDVP

FROM BICommon.WorkHour.TeamMemberWorkHourFact		hf
	INNER JOIN BICommon.TeamMember.TeamMemberDim	tmd ON tmd.TeamMemberID = hf.TeamMemberID
	INNER JOIN QLODS.dbo.EmployeeMaster				em ON em.CommonID = tmd.CommonID
	INNER JOIN BICommon.WorkHour.TimeCodeDim		tcd ON tcd.TimeCodeDimID = hf.TimeCodeDimID


WHERE 1=1
	AND hf.WorkDateID BETWEEN 20170915 AND 20170915
	AND em.OpsDVP LIKE '%Ebony%'

ORDER BY em.FullNameFirstLast
	
	
