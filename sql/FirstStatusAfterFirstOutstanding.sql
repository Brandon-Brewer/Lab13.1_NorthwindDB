SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #bp

SELECT 
  tif.LoanNumber
, [First Outstanding Date]		= MIN(tif.StatusDateTime)
INTO #bp
FROM QLODS..LKWDTrackingItemFact tif
WHERE 1=1 
	AND tif.TrackingItemID = 5298 --TI 5648 Initial Underwrite Review
	AND tif.StatusID = 11 --Outstanding
	AND tif.StatusDtID > 20150500
GROUP BY tif.LoanNumber
HAVING MIN(tif.StatusDtID) > 20160000


DROP TABLE IF EXISTS #bp2
SELECT 
  #bp.LoanNumber
, #bp.[First Outstanding Date]
, firstAfterOutstanding.StatusID
, firstAfterOutstanding.StatusDateTime
, firstAfterOutstanding.StatusUserID
INTO #bp2
FROM #bp
	OUTER APPLY(
				SELECT TOP 1
					  tif.StatusID
					, tif.StatusDateTime
					, tif.StatusUserID
				FROM QLODS..LKWDTrackingItemFact tif 
				WHERE tif.LoanNumber = #bp.LoanNumber
					AND tif.TrackingItemID = 5298
					AND tif.StatusDateTime > #bp.[First Outstanding Date]
				ORDER BY tif.StatusDtID ASC, tif.StatusTmID ASC
				)firstAfterOutstanding


SELECT
  #bp2.LoanNumber
, lpd.LoanPurpose
, pd.ProductDescription
, L.Stat60Dt
, #bp2.[First Outstanding Date]
, tisd.StatusDescription 'First Status After First Outstanding'
, #bp2.StatusDateTime 'First Status Date After First Outstanding'
, em.CommonID 'Status User'

FROM #bp2
	LEFT JOIN QLODS..LKWDTrackingItemStatusDim tisd ON tisd.StatusID = #bp2.StatusID
	LEFT JOIN QLODS..EmployeeMaster em ON em.EmployeeDimID = #bp2.StatusUserID
	LEFT JOIN QLODS..LKWD L ON L.LoanNumber = #bp2.LoanNumber
	LEFT JOIN QLODS..LoanPurposeDim lpd ON lpd.LoanPurposeID = L.LoanPurposeID
	LEFT JOIN QLODS..ProductDim pd ON pd.ProductID = L.ProductID
