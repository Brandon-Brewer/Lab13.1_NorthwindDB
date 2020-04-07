/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  whf.WorkDateID
, tmd.CommonID
, em.FullNameFirstLast
, CAST(SUM(whf.MinutesWorked)/60.0 AS numeric(9,2)) 'Hours Worked'
, em.OpsTeamLeader
, em.OpsDirector  

FROM BICommon.WorkHour.TeamMemberWorkHourFact whf
	INNER JOIN BICommon.TeamMember.TeamMemberDim tmd ON tmd.TeamMemberID = whf.TeamMemberID
	INNER JOIN BICommon.WorkHour.TimeCodeDim tcd ON tcd.TimeCodeDimID = whf.TimeCodeDimID
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = tmd.CommonID

WHERE 1=1
	AND whf.WorkDateId = 20171211
	AND (em.OpsDirector = 'Ryan Meyers'
		OR em.OpsDirector = 'Jason Halliday')
	AND tcd.TimeCodeDesignation IN ('REG', 'OT', 'IO')

GROUP BY whf.WorkDateID, tmd.CommonID, em.FullNameFirstLast, em.OpsTeamLeader, em.OpsDirector

ORDER BY em.FullNameFirstLast