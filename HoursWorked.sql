SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
  tmd.CommonID
, SUM(whf.MinutesWorked)/60.0 'HoursWorked'
, SUM(whf.MinutesWorked)/480.0 'DaysWorked'
FROM BICommon.WorkHour.TeamMemberWorkHourFact whf (NOLOCK)
	INNER JOIN BICommon.WorkHour.TimeCodeDim tcd (NOLOCK) ON tcd.TimeCodeDimID = whf.TimeCodeDimID
	INNER JOIN BICommon.TeamMember.TeamMemberDim tmd (NOLOCK) ON tmd.TeamMemberID = whf.TeamMemberID
WHERE 1=1
	AND whf.TeamMemberID = tmd.TeamMemberID
	AND whf.WorkDateID BETWEEN 20190401 AND 20190630
	AND tcd.TimeCodeDesignation IN ('IO', 'OT', 'Reg')
GROUP BY tmd.CommonID
ORDER BY tmd.CommonID