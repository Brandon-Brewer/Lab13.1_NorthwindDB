SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

DROP TABLE IF EXISTS #pipe
SELECT
  L.LoanNumber
, L.BorrowerGCID
, L.CoBorrowerGCID
, L.PropertyGeographyID
, L.CurrStatDt
, sd.StatusFullDesc 'CurrentStatus'
, lpd.LoanPurpose
, lcgd.FriendlyName 'Loan Channel'
, pb.ProductDescription
, pb.ProductBucket
INTO #pipe
FROM QLODS.dbo.LKWD L WITH (NOLOCK)
	LEFT JOIN QLODS.dbo.LoanPurposeDim lpd WITH (NOLOCK) ON lpd.LoanPurposeID = L.LoanPurposeID
	LEFT JOIN QLODS.dbo.LoanChannelGroupDim lcgd WITH (NOLOCK) ON lcgd.LoanChannelGroupID = L.LoanChannelGroupID
	LEFT JOIN Reporting.dbo.vwProductBuckets pb WITH (NOLOCK) ON pb.ProductId = L.ProductID
	LEFT JOIN QLODS.dbo.StatusDim sd WITH (NOLOCK) ON sd.StatusID = L.CurrentStatusID
WHERE 1=1
	AND sd.StatusKey IN (21, 33, 35, 40)
	AND L.Stat21ID IS NOT NULL
	AND L.LoanPurposeID = 7
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND pb.ProductBucket = 'FHA Streamline'



DROP TABLE IF EXISTS #qltoql
SELECT
  #pipe.*
INTO #qltoql
FROM #pipe
	CROSS APPLY( 
				SELECT TOP 1 *
				FROM SRC.DataLakeAMP.TrackingItemCaretDetail caret WITH (NOLOCK) 
				WHERE caret.LoanNumber = #pipe.LoanNumber
					AND caret.TrackingItem = 633
					AND caret.CaretField LIKE '%quicken%'
				) ql


DROP TABLE IF EXISTS #case
SELECT
  #qltoql.*
INTO #case
FROM #qltoql
	INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact ticsf WITH (NOLOCK) ON ticsf.LoanNumber = #qltoql.LoanNumber
		AND ticsf.TrackingItemID = 4599   --TI 2884 *Case # Assignment
		AND ticsf.StatusID = 11  --Attempted


DROP TABLE IF EXISTS #stage
SELECT
  #case.*
, cap.[FHA CASE Assignment DATE]
, cap.[CASE Number]
INTO #stage
FROM #case
	LEFT JOIN [BIG].[DataExtract].[vw_CapitalMarkets] cap WITH (NOLOCK) ON cap.[Loan Number] = #case.LoanNumber


DROP TABLE IF EXISTS #final
SELECT
  #stage.*
, serviced.LoanNumber 'Serviced Loan Number'
, serviced.[CASE Number] 'Serviced Case Number'
, serviced.[Interest Rate] 'Serviced Interest Rate'
, serviced.MIRate 'Serviced MIP Rate'
INTO #final
FROM #stage
	OUTER APPLY(
				SELECT TOP 1 L.LoanNumber, cap.[CASE Number], cap.[Interest Rate], cap.[Mortgage Insurance Premium Fee], cap.[Loan Amount]
				  , cm.MIRate
				  , cm.UFMIPaymentAmount
				  , cm.FirstMIPayment
				FROM QLODS.dbo.LKWD L WITH (NOLOCK)
					LEFT JOIN [BIG].[DataExtract].[vw_CapitalMarkets] cap WITH (NOLOCK) ON cap.[Loan Number] = L.LoanNumber
					LEFT JOIN QLODS.dbo.LKWDCapitalMarkets cm WITH (NOLOCK) ON cm.LoanNumber = L.LoanNumber
				WHERE 1=1
					AND L.BorrowerGCID = #stage.BorrowerGCID
					AND L.PropertyGeographyID = #stage.PropertyGeographyID
					AND L.ClosingID IS NOT NULL
					AND cap.[CASE Number] IS NOT NULL
				ORDER BY L.CreateDtID DESC
				) serviced


SELECT
  #final.*
, cc.[Condition Count]
FROM #final
	OUTER APPLY(
				SELECT COUNT(*) 'Condition Count'
				FROM QLODS.dbo.TrackingItemCurrentStatusFact ticsf WITH (NOLOCK)
					INNER JOIN QLODS.dbo.LKWDTrackingItemDim tid WITH (NOLOCK) ON tid.TrackingItemID = ticsf.TrackingItemID
						AND tid.ConditionType IN ('Client Conditions', 'Vendor Communication Condition')
				WHERE ticsf.LoanNumber = #final.LoanNumber
					AND ticsf.StatusID IN (6, 11, 39)
				) cc
	






SELECT #final.*
FROM #final
	INNER JOIN QLODS.dbo.TrackingItemCurrentStatusFact ticsf WITH (NOLOCK) ON ticsf.LoanNumber = #final.LoanNumber
		AND ticsf.TrackingItemID = 4599  --TI 4949 Payoff for ^creditor^ #^acct#^ received - needs review
		AND ticsf.StatusID = 11  --Outstanding



/*
SELECT
  L.LoanNumber
, L.CreateDtID
, cap.[CASE Number]
FROM QLODS.dbo.LKWD L WITH (NOLOCK)
	LEFT JOIN [BIG].[DataExtract].[vw_CapitalMarkets] cap WITH (NOLOCK) ON cap.[Loan Number] = L.LoanNumber
WHERE L.BorrowerGCID = 11655323
	AND L.PropertyGeographyID = 20778
	AND L.ClosingID IS NOT NULL
*/