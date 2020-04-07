SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #pipe
DROP TABLE IF EXISTS #pop

SELECT ticsf.LoanNumber
	, sd.StatusFullDesc
INTO #pipe

FROM QLODS..TrackingItemCurrentStatusFact ticsf
	INNER JOIN QLODS..LKWD l ON l.LoanNumber = ticsf.LoanNumber
		AND l.ReverseFlg = 0
		AND l.DeleteFlg = 0
	INNER JOIN QLODS..StatusDim sd on sd.StatusID = l.CurrentStatusID
		AND sd.StatusKey BETWEEN 21 AND 90

WHERE ticsf.TrackingItemID = 2903 --TrackingItem = 2145
	AND ticsf.StatusID = 11 --outstanding


/***********************************/

SELECT A.LoanNumber 'Loan Number'
	, A.StatusDateTime 'First Outstanding After Cleared Date'
	--, A.PrevStatusID 
	, DATEDIFF(MINUTE, A.StatusDateTime, GETDATE())/1440.0	'Days Since First Outstanding After Cleared'

INTO #pop
FROM
	(
	SELECT tif.LoanNumber
		, tif.StatusDateTime
		, tif.PrevStatusID
		, ROW_NUMBER() OVER (PARTITION BY tif.LoanNumber ORDER BY tif.StatusDateTime DESC)srank
	FROM #pipe
		INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = #pipe.LoanNumber
			AND tif.TrackingItemID = 2903

	WHERE tif.StatusID = 11 --outstanding
		AND tif.PrevStatusID IN (1,67)
	)A

WHERE A.srank = 1

ORDER BY A.StatusDateTime



/***********************************/

SELECT p.*
	, sd.StatusFullDesc 'Current Loan Status'
	, em.FullNameFirstLast 'Underwriter'
	, em.OpsTeamLeader 'TL'
	, em.OpsDirector 'OD'
	, em.OpsDVP 'DVP'
FROM #pop p
	INNER JOIN QLODS..LKWD l ON l.LoanNumber = p.[Loan Number]
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = l.CurrentStatusID
	LEFT JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = CASE WHEN l.LoanUnderwriterID IS NULL OR l.LoanUnderwriterID = 1 THEN  l.AssociateUnderwriterID ELSE l.LoanUnderwriterID END
ORDER BY p.[Days Since First Outstanding After Cleared] DESC


