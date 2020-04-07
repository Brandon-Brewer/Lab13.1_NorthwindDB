SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT LK.LoanNumber
	, PB.ProductBucket
	, PD.ProductDescription 'Product @21'


FROM QLODS..LKWD LK
	INNER JOIN Reporting.dbo.vwProductBuckets
		PB (NOLOCK) ON PB.ProductID = LK.ProductID
	INNER JOIN QLODS..ProductDim
		PD (NOLOCK) ON PD.ProductID = LK.Stat21ProductID
	CROSS APPLY(
					SELECT TIF.LoanNumber
					FROM QLODS..LKWDTrackingItemFact TIF
					WHERE TIF.LoanNumber = LK.LoanNumber 
						AND TIF.TrackingItemID IN (4893,7086)
					GROUP BY TIF.LoanNumber
				)specTI

WHERE PB.ProductBucket LIKE '%VA%'
	--PD.ProductDescription LIKE '%VA%'
	AND LK.LoanPurposeID <> 7
	AND LK.Stat21ID BETWEEN 20170400 AND 20170422
	AND LK.DeleteFlg = 0