SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

--DROP TABLE IF EXISTS #bp
SELECT
  L.LoanNumber
, dd.DateID
, tisd.StatusDescription
, ticsf.StatusUserId
, ticsf.StatusID
, dd.DayOfWeekName
, em.OpsTeamLeader
--, [count] = count(DISTINCT L.LoanNumber)

FROM QLODS..LKWD L
	INNER JOIN QLODS..TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = L.LoanNumber
		AND ticsf.TrackingItemID = 7405  --TI 8152 First48 Pilot Identifier
	INNER JOIN QLODS..DateDim dd ON dd.DateID = ticsf.StatusDtId
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = L.LoanUnderwriterID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = ticsf.StatusID
WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND EM.OpsTeamLeader LIKE '%Barb%'
	AND ticsf.StatusID = 11
--GROUP BY dd.DateID, dd.DayOfWeekName
--GROUP BY dd.DateID
ORDER BY dd.DateID