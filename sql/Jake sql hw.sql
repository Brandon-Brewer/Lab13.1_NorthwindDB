SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  --Avoids angry engineers 

--Drops a temp table if one exists
--IF OBJECT_ID('tempdb..#StartingPop','U') IS NOT NULL
       --DROP TABLE #StartingPop

SELECT Lk.LoanNumber
, lpd.LoanPurpose
, lcd.FriendlyName
, pd.ProductDescription
, sd.StatusFullDesc
, LK.CurrStatID
, [Days in Current Status]	=  DateDiff(second, LK.CurrStatDT, getdate())/86400.0
, SC.[Suspense Count]

FROM QLODS..LKWD LK
	INNER JOIN QLODS..StatusDim 
		sd ON sd.StatusID = LK.CurrentStatusID
	INNER JOIN QLODS..LoanPurposeDim
		lpd ON lpd.LoanPurposeID = Lk.LoanPurposeID
	INNER JOIN QLODS..LoanChannelGroupDim
		lcd ON lcd.LoanChannelGroupID = Lk.LoanChannelGroupID
	INNER JOIN QLODS..ProductDIM
		pd ON pd.ProductID = LK.ProductID
	OUTER APPLY (
				SELECT COUNT(*) AS [Suspense Count]
				FROM QLODS..LKWDTransFact ltf
				WHERE ltf.LoanNumber = LK.LoanNumber
					AND ltf.EventtypeID = 2
					AND ltf.StatusID = 117
					AND ltf.Rollbackflg = 0
					AND ltf.Deleteflg = 0
				GROUP BY ltf.LoanNumber
				) SC	

WHERE sd.StatusKey = 35
		AND LK.ReverseFlg = 0
		AND LK.DeleteFlg = 0
