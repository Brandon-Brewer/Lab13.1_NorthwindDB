SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
  L.LoanNumber
--, tif.StatusDateTime 'TI 6449 Status Date'
--, pb.ProductBucket
--, L.LoanPurposeID
--, sd.StatusKey
--, [Units]				=  CASE WHEN pb.ProductBucket = 'Conventional' THEN 1.75
--								WHEN pb.ProductBucket = 'FHA' THEN 2.25
--								WHEN pb.ProductBucket = 'VA' THEN 2
--								WHEN pb.ProductBucket = 'Jumbo' THEN 2.5
--								ELSE 9000 END
--, em.FullNameFirstLast 'FSO UW'

FROM QLODS..LKWD L
--	INNER JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = L.LoanUnderwriterFinalSignOffID
	INNER JOIN QLODS..StatusDim SD ON SD.StatusID = L.CurrentStatusID
	--INNER JOIN Reporting.dbo.vwProductBuckets pb ON pb.ProductId = L.ProductID
	INNER JOIN QLODS..LKWDTrackingItemFact tif ON tif.LoanNumber = L.LoanNumber
					AND tif.DeleteFlg = 0
					AND tif.TrackingItemID = 6195 --TI 6449 Pre Final Sign Off Review Needed
					AND tif.StatusID IN (58, 100) --Completed/Confirmed, Cancelled Tracking Item
					AND tif.StatusDtID BETWEEN 20170600 AND 201706099
WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND (L.Stat40ID BETWEEN 20170600 AND 20170699
		OR SD.StatusKey IN (21,33,35,40,41,42))