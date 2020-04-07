Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #users
SELECT DISTINCT tif.StatusUserID
INTO #users
FROM BISandboxWrite.bb.first48loans bb
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = bb.LoanNumber
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem IN (8156,8154,8153,8155,7626,5324,8161)
	AND tif.StatusID IN (67,98,58,127,49)
	AND tif.DeleteFlg = 0
	--AND bb.Pilot = 1



SELECT [Total Hours]	= SUM(wh.MinutesWorked)/60.0
FROM #users u 
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.EmployeeDimID = u.StatusUserID
	INNER JOIN BICommon.TeamMember.TeamMemberDim TMD ON TMD.EmployeeDimID= em.EmployeeDimID
	INNER JOIN BICommon.WorkHour.TeamMemberWorkHourFact wh ON wh.TeamMemberID = TMD.TeamMemberID
WHERE em.JobGroup = 'TM'


SELECT COUNT(*)
FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem IN (8156,8154,8153,8155,7626,5324,8161)
	AND tif.StatusID IN (67,98,58,127,49)
	AND tif.StatusDtID BETWEEN 20170400 AND 20170499
	AND tif.DeleteFlg = 0