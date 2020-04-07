SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  

SELECT 
	  L.LoanNumber				'Loan Number'
	, TID.TrackingItemDesc		'Tracking Item'
	, [Status Date]				= DD.[DayName]
	, EM.FullNameFirstLast		'Status User'
	, EM.OpsTeamLeader			'Team Leader'
	, EM.OpsDirector			'Director'
	, EM.OpsDVP					'DVP'
	, [Help Requested]			= CASE WHEN TIF.StatusID = 127 THEN 1 ELSE 0 END
	, [Completed]				= CASE WHEN TIF.StatusID = 98 THEN 1 ELSE 0 END
	, [Need Documentation]		= CASE WHEN TIF.StatusID = 78 THEN 1 ELSE 0 END


FROM QLODS..LKWD L
	INNER JOIN QLODS..LKWDTrackingItemFact
		TIF ON TIF.LoanNumber = L.LoanNumber
	INNER JOIN QLODS..LKWDTrackingItemDim
		TID ON TID.TrackingItemID = TIF.TrackingItemID
	INNER JOIN QLODS..EmployeeMaster
		EM ON EM.EmployeeDimID = TIF.StatusUserID
	INNER JOIN QLODS..DateDim
		DD ON DD.DateID = TIF.StatusDtID

WHERE TIF.StatusID IN (127,98,78) --Help Requested, Completed, Need Documentation respectively
	AND TIF.TrackingItemID IN (4893,7086,7448) --Income/Credit/Asset Spec Review Required Tracking Items, respectively
	AND TIF.StatusDtID BETWEEN 20170423 AND 20170429  --I believe we want Previous week, however this must be confirmed with 
	AND TIF.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.DeleteFlg = 0




