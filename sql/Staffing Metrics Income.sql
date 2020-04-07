SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#basePop','U') IS NOT NULL
       DROP TABLE #basePop

SELECT 
	[Loan Number]			= LK.LoanNumber
	, [Stat 21 Month]		= DD.MonthName
	, [Self Employed]		= CASE WHEN LK.SelfEmployFlg = 1 THEN 'Yes' ELSE 'No' END
	, [Channel]				= LCG.FriendlyName
	, [Product Type]		= PD.ProductType
	, [Loan Purpose]		= LPD.LoanPurpose
	, [FICO]				= LK.FICO
	, [Funds to Close]		= CM.CashReqToClose
	, [FHA and FICO<620]	= CASE WHEN LK.FICO < 620 AND PD.ProductDescription LIKE '%FHA%' THEN 'Yes' ELSE 'No' END
	, [Funds to Close > 0]	= CASE WHEN CM.CashReqToClose > 0 THEN 'Yes' ELSE 'No' END
	, [Team Member Loan]	= CASE WHEN LK.EmployeeLoanFlg = 1 THEN 'Yes' ELSE 'No' END
	, [TI 8152 Present]		= CASE WHEN TIF2.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END
	, [TI 4745 Present]		= CASE WHEN TIF3.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END
	, [TI 6329 Present]		= CASE WHEN TIF4.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END

FROM QLODS..LKWD LK
	INNER JOIN QLODS..LKWDTrackingItemFact 
		TIF ON TIF.LoanNumber = LK.LoanNumber
	INNER JOIN QLODS..LoanChannelGroupDim 
		LCG ON LCG.LoanChannelGroupID = LK.LoanChannelGroupID
	INNER JOIN QLODS..ProductDim
		PD ON PD.ProductID = LK.ProductID
	INNER JOIN QLODS..LoanPurposeDim
		LPD ON LPD.LoanPurposeID = LK.LoanPurposeID
	INNER JOIN QLODS..DateDim
		DD ON DD.DateID = LK.Stat21ID
	LEFT JOIN QLODS..LKWDCapitalMarkets
		CM ON CM.LoanNumber = LK.LoanNumber
	LEFT JOIN QLODS..LKWDTrackingItemFact
		TIF2 ON TIF2.LoanNumber = LK.LoanNumber
		AND TIF2.TrackingItemID = 7405  --Tracking Item 8152 "First48 Pilot Identifier"
		AND TIF2.StatusSeqNum = 1
	LEFT JOIN QLODS..LKWDTrackingItemFact
		TIF3 ON TIF3.LoanNumber = LK.LoanNumber
		AND TIF3.TrackingItemID = 4477  --Tracking Item 4745 "Re-Underwrite: Full Underwriter Review Required"
		AND TIF3.StatusSeqNum = 1
	LEFT JOIN QLODS..LKWDTrackingItemFact
		TIF4 ON TIF4.LoanNumber = LK.LoanNumber
		AND TIF4.TrackingItemID = 5780  --Tracking Item 6329 "Underwriter: Advanced Income Review Required"
		AND TIF4.StatusSeqNum = 1


WHERE LK.Stat21ID BETWEEN 20161000 AND 20170415 --Went in Stat 21 for the last 6 months (since October 1)
	AND TIF.TrackingItemID = 4893 --TrackingItem 5234 'Income Specialist Review Required".  This can be changed for the second part of the metrics.
	AND LK.DeleteFlg = 0
	AND LK.ReverseFlg = 0

	


/*

SELECT bp.*

FROM #basePop bp 
*/

	