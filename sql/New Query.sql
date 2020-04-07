/****************************************************************

****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #t
SELECT DISTINCT
  tif.LoanNumber
, tif.TrackingSeqNum
--, tif.StatusSeqNum
, tif.StatusDateTime
--, ROW_NUmber() OVER(Partition by tif.LoanNumber, tif.TrackingSeqNum, tif.StatusDateTime ORDER BY tif.StatusSeqNum)
INTO #t
FROM QLODS.dbo.LKWD L
	INNER JOIN QLODS.dbo.LKWDTrackingItemFact tif ON tif.LoanNumber = l.LoanNumber
WHERE 1=1
	AND tif.TrackingItemID = 5659
	AND L.LoanNumber = '3382564181'


SELECT *
, ROW_NUMBER() OVER(Partition by #t.LoanNumber, #t.TrackingSeqNum ORDER BY #t.StatusDateTime)
FROM #t