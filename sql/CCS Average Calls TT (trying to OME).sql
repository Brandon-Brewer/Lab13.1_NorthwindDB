SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp
SELECT
  cf.JacketNumber				'Loan Number'
, cf.StartDateID				'Call Date'
, ome.OnlineStatus				'Online Status (at time of call)'
, em.FullNameFirstLast			'Call Routed to'
, em.OpsTeamLeader				'Ops Team Leader'
, em.OpsDirector				'Ops Director'
, em.OpsDVP						'Ops DVP'
, cf.StartDateTime				'Call Start Time'
, cf.EndDateTime				'Call End Time'
, cf.Duration					'Call Duration (seconds)'
INTO #bp

FROM BICallData.dbo.CallFact			cf
	INNER JOIN QLODS.dbo.LKWD			L	ON L.LoanNumber = cf.JacketNumber
	LEFT JOIN BICommon.TeamMember.HierarchyFUllyConnected hfc ON hfc.DescendantCommonID = cf.CallEmployeeCommonID
		AND CONVERT(VARCHAR(8), cf.StartDateID, 112) BETWEEN hfc.ActiveStartDtID AND hfc.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleBridge jtb ON jtb.CommonID = hfc.AncestorCommonID
		AND CONVERT(VARCHAR(8), cf.StartDateID, 112) BETWEEN jtb.ActiveStartDtID AND jtb.ActiveEndDtID
	INNER JOIN BICommon.TeamMember.JobTitleDim jtdim ON jtdim.JobTitleID = jtb.JobTitleID
		AND (jtdim.JobTitle LIKE '%DVP%'
		OR jtdim.JobTitle LIKE '%Divisional VP%')
	INNER JOIN QLODS.dbo.EmployeeMaster	em	ON em.CommonID = cf.CallEmployeeCommonID
	LEFT JOIN Reporting.dbo.vw_OME ome ON ome.LoanNUmber = cf.JacketNumber
		AND cf.StartDateTime BETWEEN ome.StartDateTime and ome.EndStatusDateTime --Online status at time of the call
				
WHERE 1=1
	AND cf.StartDateID BETWEEN 20170703 AND 20171013	--Only want yesterday's calls
	AND cf.CallDirectionID = 2	--Inbound calls
	AND em.OpsDVPCommonID = 1000329
	--AND em.OpsDVPCommonID IN (1003879, 1001093, 1002402, 1000329)
	AND cf.CallOutComeID IN (18,27,48) -- call outcome connected

--ORDER BY cf.StartTimeID


SELECT
	  #bp.[Call Date]
	, count(Distinct #bp.[Call Routed to]) 'count of ccs'
	, sum(#bp.[Call Duration (seconds)]) 'Talk Time'
	, count(#bp.[Call Duration (seconds)]) 'Number of Calls'
FROM #bp 
--WHERE #bp.[Online Status (at time of call)] = 'Online'
GROUP BY #bp.[Call Date]