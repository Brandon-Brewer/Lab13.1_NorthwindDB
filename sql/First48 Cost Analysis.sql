Set Transaction Isolation Level Read Uncommitted

DROP TABLE IF EXISTS #users
SELECT DISTINCT tif.StatusUserID
INTO #users
FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem IN (8156,8154,8153,8155,7626,5324,8161)
	AND tif.StatusID IN (67,98,58,127,49)
	AND tif.StatusDtID BETWEEN 20170400 AND 20170499
	AND tif.DeleteFlg = 0


SELECT [Total Hours]	= SUM(wh.MinutesWorked)/60.0
FROM #users u 
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.EmployeeDimID = u.StatusUserID
	INNER JOIN BICommon.TeamMember.TeamMemberDim TMD ON TMD.EmployeeDimID= em.EmployeeDimID
	INNER JOIN BICommon.WorkHour.TeamMemberWorkHourFact wh ON wh.TeamMemberID = TMD.TeamMemberID
WHERE wh.WorkDateID BETWEEN 20170400 AND 20170499
	AND em.JobGroup = 'TM'





SELECT COUNT(*)
FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem IN (8156,8154,8153,8155,7626,5324,8161)
	AND tif.StatusID IN (67,98,58,127,49)
	AND tif.StatusDtID BETWEEN 20170400 AND 20170499
	AND tif.DeleteFlg = 0
	--Select Top 1000 W.*
	--, MinutesWorked/60 'Hours worked'
	--, EM.FullNameFirstLast
	--, EM.JobTitle
	-- FROM BICommon.WorkHour.TeamMemberWorkHourFact W
	--	Inner Join BICommon.TeamMember.TeamMemberDim TMD ON TMD.TeamMemberID = W.TeamMemberID
	--	Inner Join QLODS..EmployeeMaster EM ON EM.CommonID = TMD.CommonID
	--	Order By WorkDateID DESC













DROP TABLE IF EXISTS #users
SELECT DISTINCT tif.StatusUserID
INTO #users
FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem = 5648
	AND tif.StatusID IN (67,98)
	AND tif.StatusDtID BETWEEN 20170400 AND 20170499
	AND tif.DeleteFlg = 0


SELECT [Total Hours]	= SUM(wh.MinutesWorked)/60.0
FROM #users u 
	INNER JOIN QLODS.dbo.EmployeeMaster em ON em.EmployeeDimID = u.StatusUserID
	INNER JOIN BICommon.TeamMember.TeamMemberDim TMD ON TMD.EmployeeDimID= em.EmployeeDimID
	INNER JOIN BICommon.WorkHour.TeamMemberWorkHourFact wh ON wh.TeamMemberID = TMD.TeamMemberID
WHERE wh.WorkDateID BETWEEN 20170400 AND 20170499
	AND em.JobGroup = 'TM'



SELECT COUNT(*)
FROM QLODS..LKWDTrackingItemFact tif
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = tif.TrackingItemID
WHERE tid.TrackingItem = 5648
	AND tif.StatusID IN (67,98)
	AND tif.StatusDtID BETWEEN 20170400 AND 20170499
	AND tif.DeleteFlg = 0