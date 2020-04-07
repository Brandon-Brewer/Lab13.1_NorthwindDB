SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT 
	LK.LoanNumber
	, TItype.*
	, [Stat 21 Month]		= DD.MonthName
	, [Self Employed]		= CASE WHEN LK.SelfEmployFlg = 1 THEN 'Yes' ELSE 'No' END
	, [Channel]				= LCG.FriendlyName
	, [Product Type]		= PD.ProductType
	, [Product Group]		= PB.ProductBucket
	, [Loan Purpose]		= LPD.LoanPurpose
	, [FICO]				= LK.FICO
	, [Funds to Close]		= CM.CashReqToClose
	, [FHA and FICO<620]	= CASE WHEN LK.FICO < 620 AND PD.ProductDescription LIKE '%FHA%' THEN 'Yes' ELSE 'No' END
	, [Funds to Close > 0]	= CASE WHEN CM.CashReqToClose > 0 THEN 'Yes' ELSE 'No' END
	, [Team Member Loan]	= CASE WHEN LK.EmployeeLoanFlg = 1 THEN 'Yes' ELSE 'No' END
	, [TI 8152 Present]		= CASE WHEN ti8152.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END
	, [TI 4745 Present]		= CASE WHEN ti4745.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END
	, [TI 6329 Present]		= CASE WHEN ti6329.LoanNumber IS NULL THEN 'No' ELSE 'Yes' END
	, [Count of PR TIs]		= prcount.PRs

FROM QLODS..LKWD LK
	INNER JOIN QLODS..LoanChannelGroupDim 
		LCG (NOLOCK) ON LCG.LoanChannelGroupID = LK.LoanChannelGroupID
	INNER JOIN QLODS..ProductDim
		PD (NOLOCK) ON PD.ProductID = LK.ProductID
	INNER JOIN QLODS..LoanPurposeDim
		LPD (NOLOCK) ON LPD.LoanPurposeID = LK.LoanPurposeID
	INNER JOIN QLODS..DateDim
		DD (NOLOCK) ON DD.DateID = LK.Stat21ID
	INNER JOIN Reporting.dbo.vwProductBuckets
		PB (NOLOCK) ON PB.ProductID = LK.ProductID
	LEFT JOIN QLODS..LKWDCapitalMarkets
		CM (NOLOCK) ON CM.LoanNumber = LK.LoanNumber
	OUTER APPLY (
					SELECT TIF2.LoanNumber
					FROM QLODS..LKWDTrackingItemFact TIF2
					WHERE TIF2.LoanNumber = LK.LoanNumber
						AND TIF2.TrackingItemID = 7405  --Tracking Item 8152 "First48 Pilot Identifier"
						AND TIF2.StatusSeqNum = 1
					GROUP BY TIF2.LoanNumber
				)ti8152
	
	OUTER APPLY (
					SELECT TIF3.LoanNumber
					FROM QLODS..LKWDTrackingItemFact TIF3
					WHERE TIF3.LoanNumber = LK.LoanNumber
						AND TIF3.TrackingItemID = 4477  --Tracking Item 4745 "Re-Underwrite: Full Underwriter Review Required"
						AND TIF3.StatusSeqNum = 1
					GROUP BY TIF3.LoanNumber
				)ti4745

	OUTER APPLY ( 
					SELECT TIF4.LoanNumber
					FROM QLODS..LKWDTrackingItemFact TIF4
					WHERE TIF4.LoanNumber = LK.LoanNumber
						AND TIF4.TrackingItemID = 5780  --Tracking Item 6329 "Underwriter: Advanced Income Review Required"
						AND TIF4.StatusSeqNum = 1
					GROUP BY TIF4.LoanNumber
				)ti6329

	CROSS APPLY ( 
					SELECT CASE WHEN SUM(CASE WHEN TIF5.TrackingItemID = 4893 THEN 1 ELSE 0 END) > 0 THEN 'Yes' ELSE 'No' END 'Income (5234)'
						, CASE WHEN SUM(CASE WHEN TIF5.TrackingItemID = 7086 THEN 1 ELSE 0 END) > 0 THEN 'Yes' ELSE 'No' END 'Credit (7626)'
						, CASE WHEN SUM(CASE WHEN TIF5.TrackingItemID = 4476 THEN 1 ELSE 0 END) > 0 THEN 'Yes' ELSE 'No' END 'Associate (4744)'
					FROM QLODS..LKWDTrackingItemFact TIF5
					WHERE TIF5.LoanNumber = LK.LoanNumber
						AND TIF5.TrackingItemID IN (4893,7086,4476)  --Tracking Items 5234, 7626, 4744 (Income/Credit/Associate Review)
						AND TIF5.StatusSeqNum = 1
					GROUP BY TIF5.LoanNumber
				)TItype


	OUTER APPLY (
					SELECT PRs = COUNT(*)
					FROM QLODS..LKWDTrackingItemFact TIFcount
					WHERE TIFcount.LoanNumber = LK.LoanNumber
						AND TIFcount.TrackingItemID IN (7242,7243,4900,7208,7244,7228,3125,7229) --PR tracking items from Woz's Email
						AND TIFcount.StatusSeqNum = 1
				)prcount



WHERE LK.Stat21ID BETWEEN 20161000 AND 20170422 --From loans that went Stat 21 for the last 6 months
	AND LK.DeleteFlg = 0
	AND LK.ReverseFlg = 0
	