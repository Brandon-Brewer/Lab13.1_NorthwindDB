Set Transaction Isolation Level Read Uncommitted


----------- Q1 -----------

Select LK.LoanNumber
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
			-- Remember that doing this with IDs is more efficient than using Stat21Dt variable

From QLODS..LKWD LK  (NOLOCK)

Where LK.ClosingID BETWEEN 20170000 AND 20170500

SELECT * FROM QLODS..TimeDim 

























----------- Q2 -----------

Select LK.LoanNumber
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
			-- Remember that doing this with IDs is more efficient than using Stat21Dt variable
	, [Last Stat21 OR FlipDt to Last Stat41]		= CASE WHEN LK.FlipDt IS NULL THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt > LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.FlipDt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt < LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
																END
From QLODS..LKWD LK  (NOLOCK)

Where LK.ClosingID BETWEEN 20170000 AND 20170500










----------- Q3 -----------

Select LK.LoanNumber
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
			-- Remember that doing this with IDs is more efficient than using Stat21Dt variable
	, [Last Stat21 OR FlipDt to Last Stat41]		= CASE WHEN LK.FlipDt IS NULL THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt > LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.FlipDt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt < LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
																END
	, SuspenseFlg									= CASE WHEN SUSP.LoanNumber IS NULL THEN 'NO' ELSE 'YES' END
From QLODS..LKWD
LK  (NOLOCK)
	OUTER APPLY ( Select Top 1 TF.LoanNumber
					From QLODS..LKWDTransFact
					TF  (NOLOCK)
					Where TF.LoanNumber = LK.LoanNumber
						AND TF.EventTypeID = 2 -- Status Change
						AND TF.StatusID = 117 -- Suspense
					/*Order By TF.TransDtID DESC, TF.TransTmID DESC*/) SUSP
Where LK.ClosingID BETWEEN 20170000 AND 20170500





----------- Q4 -----------

DECLARE @CurrentMonth INT = (Select DD.MonthKey
								FROM QLODS..DateDim DD
								Where DD.DateID = CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT))

Select COUNT(*) 'Folders'
	--, FORMAT( COUNT(*) , '###,###,#00.00')
	--, FORMAT( COUNT(*) , '###,###,###')
FROM QLODS..LKWDTransFact LTF
	Inner Join QLODS..StatusDim SD ON SD.StatusID = LTF.StatusID
	Inner Join QLODS..DateDim DD ON DD.DateID = LTF.TransDtID
Where LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 76 -- Folder Recieved (Stat 21)
	AND DD.MonthKey = @CurrentMonth




----------- Q5 -----------

DECLARE @CurrentMonth INT = (Select DD.MonthKey
								FROM QLODS..DateDim DD
								Where DD.DateID = CAST(CONVERT(VARCHAR(8),CONVERT(DATE,GETDATE()),112) AS INT))

Select TD.HourName
	, COUNT(*) 'Folders'
	--, FORMAT( COUNT(*) , '###,###,#00.00')
	--, FORMAT( COUNT(*) , '###,###,###')
FROM QLODS..LKWDTransFact LTF
	Inner Join QLODS..StatusDim SD ON SD.StatusID = LTF.StatusID
	Inner Join QLODS..DateDim DD ON DD.DateID = LTF.TransDtID
	Inner Join QLODS..TimeDim TD ON TD.TimeID = LTF.TransTmID
Where LTF.EventTypeID = 2 -- Status Change
	AND LTF.StatusID = 76 -- Folder Recieved (Stat 21)
	AND DD.MonthKey = @CurrentMonth

Group By TD.HourName
Having COUNT(*) >= 2000
Order By COUNT(*) DESC
