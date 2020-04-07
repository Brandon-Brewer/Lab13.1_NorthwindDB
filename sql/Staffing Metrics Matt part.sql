SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT LK.LoanNumber
	, [Stat 20 Month]	= DD.MonthName
	, [Purchase]		= CASE WHEN LK.LoanPurposeID <> 7 THEN 1 ELSE 0 END
	, [Jumbo]			= PB.JumboFlg
	, [Schwab]			= CASE WHEN LK.LoanChannelGroupID IN (30,57,68,81,100) THEN 1 ELSE 0 END
	, [FHA Streamlines]	= CASE WHEN PB.ProductBucket = 'FHA Streamline' THEN 1 ELSE 0 END
	, [VA Streamlines]	= CASE WHEN PB.ProductBucket = 'VA Streamline' THEN 1 ELSE 0 END
	, [VA Refi]			= CASE WHEN PB.ProductBucket = 'VA'
								AND LK.LoanPurposeID = 7
								AND PB.Jumboflg = 0
								AND CASE WHEN LK.LoanChannelGroupID IN (30,57,68,81,100) THEN 1 ELSE 0 END = 0
								THEN 1 ELSE 0 END
	, [Other]			= CASE WHEN PB.ProductBucket IN ('Conventional', 'FHA', 'VA')
								AND LK.LoanPurposeID = 7 
								AND PB.Jumboflg = 0
								AND CASE WHEN PB.ProductBucket = 'VA' AND LK.LoanPurposeID = 7 THEN 1 ELSE 0 END = 0
								AND CASE WHEN LK.LoanChannelGroupID IN (30,57,68,81,100) THEN 1 ELSE 0 END = 0
								THEN 1 ELSE 0 END

FROM QLODS..LKWD LK
	INNER JOIN QLODS..DateDim
		DD ON DD.DateID = LK.Stat20ID
	INNER JOIN Reporting.dbo.vwProductBuckets
		PB ON PB.ProductID = LK.ProductID 

WHERE LK.Stat20ID BETWEEN 20161000 AND 20170422
	AND LK.DeleteFlg = 0
	AND LK.ReverseFlg = 0
