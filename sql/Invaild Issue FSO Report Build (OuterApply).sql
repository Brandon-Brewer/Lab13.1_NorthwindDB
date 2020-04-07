SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
  L.LoanNumber				'Loan Number'
, tid.TrackingItem
, tisd.StatusDescription
, ticsf.StatusDateTime
, em.FullNameFirstLast
, em.CommonID
--, Tracking Item Insert Date
, lpd.LoanPurpose			'Loan Purpose'
, rp.ProductGroup
--Previous Status User
--, CAST(CONVERT(varchar(8), ticsf.PrevStatusDTID, 112) AS datetime) --Date Time is used in qslice report.
, [Prev Status Date] = prev.StatusDateTime
--, tisd2.StatusDescription 'Prev Status Description'
, ticsf.TrackingSeqNum
--Previous Status User CommonID
--Product (bucket)
--, [Time Since First Status]			= DATEDIFF(DAY, ticsf.PrevStatusDTID, GETDATE()) Need to convert to date time
, [Time In Current Status]	= DATEDIFF(DAY, ticsf.StatusDateTime, GETDATE())
--TI Insert USER
--Leader
--Director
--DVP

FROM QLODS..LKWD L
	INNER JOIN QLODS..TrackingItemCurrentStatusFact ticsf ON ticsf.LoanNumber = L.LoanNumber
		AND ticsf.TrackingItemID IN (7253, 7100)
		AND ticsf.StatusID <> 100
	INNER JOIN QLODS..LKWDTrackingItemDim tid ON tid.TrackingItemID = ticsf.TrackingItemID
	INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = ticsf.StatusID
	--INNER JOIN QLODS..LKWDTrackingItemStatusDim tisd2 ON tisd.StatusID = ticsf.PrevStatusId
	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = ticsf.StatusUserId
	--INNER JOIN QLODS..EmployeeMaster em2 ON em2.EmployeeDimID = ticsf.PrevStatusId  --Need prev status user
	INNER JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	INNER JOIN RockWorld..RWCapProductGrp rp ON rp.PDProductID = L.ProductID
	INNER JOIN QLODS..StatusDim sd ON sd.StatusID = L.CurrentStatusID
	OUTER APPLY (
				SELECT TOP 1 tif.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = ticsf.LoanNumber
					AND tif.TrackingItemID = ticsf.TrackingItemID
					AND tif.TrackingSeqNum = ticsf.TrackingSeqNum
					AND tif.StatusDateTime < ticsf.StatusDateTime
				ORDER BY tif.StatusDtID DESC, tif.StatusTmID DESC
				) prev

WHERE sd.StatusKey BETWEEN 21 AND 90
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	
	
