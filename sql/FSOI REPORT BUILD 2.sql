Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #yo
SELECT L.LoanNumber, sd.StatusFullDesc
INTO #yo

FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = L.LoanNumber
	INNER JOIN QLODS.dbo.LKWDTrackingItemStatusDim tisd ON tisd.StatusID = ticsf.StatusID
	INNER JOIN QLODS.dbo.StatusDim sd ON sd.StatusID = L.CurrentStatusID

WHERE ticsf.TrackingItemID IN (7253, 7100) --Pre-FSOI Audit, FSOI Audit
	AND ticsf.StatusID <> 100 --Cancelled Tracking Item
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND sd.StatusKey <= 90

SELECT * FROM #yo
