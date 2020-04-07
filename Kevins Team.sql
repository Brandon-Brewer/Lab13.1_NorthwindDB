SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #uw
SELECT
  em.CommonID
, em.FullNameFirstLast
, em.JobTitle
, em.StartDate
, em.SupervisoryOrgCodeDescription
, em.OpsTeamLeader
, em.OpsDirector
, em.OpsDVP
INTO #uw
FROM QLODS.dbo.EmployeeMaster em WITH (NOLOCK)
WHERE 1=1
	--AND (DATEDIFF(second, em.StartDate, GETDATE()) / 86400.0) <= 186
	AND (em.JobTitle LIKE '%Underw%'
		OR em.JobTitle LIKE '%Loan A%')
	AND (em.OpsDVPCommonID IN (2019005, 2014846)
	OR em.OpsDirectorCommonID IN (1007411, 1001928, 2202235, 2230605, 2023348))
ORDER BY (DATEDIFF(second, em.StartDate, GETDATE()) / 86400.0) DESC



SELECT
  #uw.CommonID
, #uw.FullNameFirstLast
, #uw.JobTitle
, #uw.StartDate 'QL Start Date'
, #uw.SupervisoryOrgCodeDescription
, #uw.OpsTeamLeader
, #uw.OpsDirector
, #uw.OpsDVP
, MIN(dd.[Date]) 'UW Start Date'
FROM #uw
	LEFT JOIN BICommon.TeamMember.JobTitleBridge jtb WITH (NOLOCK) ON jtb.CommonID = #uw.CommonID
	INNER JOIN BICommon.TeamMember.JobTitleDim jtd WITH (NOLOCK) ON jtd.JobTitleID = jtb.JobTitleID
		AND (jtd.JobTitle LIKE '%Underw%'
		OR jtd.JobTitle LIKE '%Loan A%')
	INNER JOIN QLODS.dbo.DateDim dd WITH (NOLOCK) ON dd.DateID = jtb.ActiveStartDtID
GROUP BY
  #uw.CommonID
, #uw.FullNameFirstLast
, #uw.JobTitle
, #uw.StartDate
, #uw.SupervisoryOrgCodeDescription
, #uw.OpsTeamLeader
, #uw.OpsDirector
, #uw.OpsDVP