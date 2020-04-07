/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
whf.WorkDateID
, CAST(SUM(whf.MinutesWorked)/60.0 AS numeric(9,2)) 'Hours Worked'
, tmd.CommonID 'CCS Common ID'
, em.FullNameFirstLast 'CCS'
, em.OpsTeamLeader 'CCS Leader'
, em.OpsDirector 'CCS Director'

FROM BICommon.WorkHour.TeamMemberWorkHourFact whf
	INNER JOIN BICommon.TeamMember.TeamMemberDim tmd ON tmd.TeamMemberID = whf.TeamMemberID
	INNER JOIN BICommon.WorkHour.TimeCodeDim tcd ON tcd.TimeCodeDimID = whf.TimeCodeDimID
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.CommonID = tmd.CommonID
	LEFT JOIN BICommon.TeamMember.HierarchyFUllyConnected hfc ON hfc.DescendantCommonID = tmd.CommonID
		AND whf.WorkDateID BETWEEN hfc.ActiveStartDtID AND hfc.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleBridge jtb ON jtb.CommonID = hfc.AncestorCommonID
		AND whf.WorkDateID BETWEEN jtb.ActiveStartDtID AND jtb.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleDim jtdim ON jtdim.JobTitleID = jtb.JobTitleID
		AND jtdim.JobTitle LIKE '%Dir, Comm%'	
	INNER JOIN QLODS.dbo.EmployeeMaster em2 ON em2.CommonID = hfc.AncestorCommonID
	
	--INNER JOIN BICommon.TeamMember.vwTeamMemberHierarchyUnPivot tmh ON tmh.LeafCommonID = tmd.CommonID
		--AND whf.WorkDateID BETWEEN tmh.ActiveStartDtID AND tmh.ActiveEndDtID
		--AND tmh.LeaderName = 'Wieske, Elizabeth'

WHERE 1=1
	AND whf.WorkDateID = 20171130
	AND (tcd.TimeCodeDesignation = 'REG'
		OR tcd.TimeCodeDesignation = 'OT')
	AND em2.FullNameFirstLast = 'Elizabeth Wieske'

GROUP BY whf.WorkDateID, tmd.CommonID, em.FullNameFirstLast, em.OpsTeamLeader, em.OpsDirector