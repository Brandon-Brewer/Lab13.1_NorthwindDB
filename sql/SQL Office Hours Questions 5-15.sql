Set Transaction Isolation Level Read Uncommitted

/*
Question 1
Find all the loans that closed between January 1st 2017 and April 30th 2017. 
Get the Loan Number, Status 21 Date Time, and Status 41 Date Time; 
Use the DATEADD function to get the Status Date Times (a.k.a using the StatusIDs)
*/

Select LK.LoanNumber
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
			-- Remember that doing this with IDs is more efficient than using Stat21Dt variable

From QLODS..LKWD LK  (NOLOCK)

Where LK.ClosingID BETWEEN 20170000 AND 20170500





/*
Question 2
Add a CASE Statement to the query from Q1 to find the Last Stat 21 or Flip Date to the Last Stat 41 Turn Time.
*/

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




/*
Question 3
Now add a Suspense "flag" using an Outer Apply and a CASE Statement.
*/

Select LK.LoanNumber
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
			-- Remember that doing this with IDs is more efficient than using Stat21Dt variable
	, [Last Stat21 OR FlipDt to Last Stat41]		= CASE WHEN LK.FlipDt IS NULL THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt > LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.FlipDt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt < LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
																END
	, SuspenseFlg									= CASE WHEN SUSP.LoanNumber IS NULL THEN 'NO' ELSE 'YES' END
From QLODS..LKWD
LK  (NOLOCK)
	OUTER APPLY ( Select Top 1 TF.LoanNumber
					From QLODS..LKWDTransFact TF  (NOLOCK)
					Where TF.LoanNumber = LK.LoanNumber
						AND TF.EventTypeID = 2 -- Status Change
						AND TF.StatusID = 117 -- Suspense
				) SUSP
Where LK.ClosingID BETWEEN 20170000 AND 20170500





/*
Question 4
Write a new query to get a count of the MTD Folders.
Utilize the DateDim table.
*/

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





/*
Question 5
Add to the Q4 query.
Get a count of Folders by the hour.
Only return the hours with more than 2000 Folders.
*/

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
Having COUNT(*) > 2000
Order By COUNT(*) DESC





/*
Question 6
Lets take the Query from Q2 and find the First Stat21 (Or Flip Date) to First Stat 41 Turn Time.
Use the same case statement, but we will need to use some Outer Applys to find the first Statuses.
*/

Select LK.LoanNumber
	, LK.FlipDt
	, [First Stat 21]								= Folder.[First Date]
	, [Status 21 Dt]								= DATEADD(SECOND, LK.Stat21TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat21ID,112)))
	, [First Stat 41]								= FSO.[First Date]
	, [Status 41 Dt]								= DATEADD(SECOND, LK.Stat41TmID-1, CONVERT(DATETIME,CONVERT(VARCHAR(8),LK.Stat41ID,112)))
	, [Last Stat21 OR FlipDt to Last Stat41]		= CASE WHEN LK.FlipDt IS NULL THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt > LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.FlipDt,LK.Stat41Dt)/1440.0
															WHEN LK.FlipDt < LK.Stat21Dt THEN DATEDIFF(MINUTE,LK.Stat21Dt,LK.Stat41Dt)/1440.0
																END
	, [First Stat21 OR FlipDt to First Stat41]		= CASE WHEN LK.FlipDt IS NULL THEN DATEDIFF(MINUTE,Folder.[First Date],FSO.[First Date])/1440.0
															WHEN LK.FlipDt > Folder.[First Date] THEN DATEDIFF(MINUTE,LK.FlipDt,FSO.[First Date])/1440.0
															WHEN LK.FlipDt < Folder.[First Date] THEN DATEDIFF(MINUTE,Folder.[First Date],FSO.[First Date])/1440.0
																END

From QLODS..LKWD LK  (NOLOCK)

	OUTER APPLY(	SELECT Top 1 TF.TransDateTime 'First Date'
					FROM QLODS..LKWDTransFact TF  (NOLOCK)
					WHERE TF.LoanNumber = LK.LoanNumber
						AND TF.EventTypeID = 2 -- Status Change
						AND TF.StatusID = 76 --Stat 21 Folder Received
					Order By TF.TransDtID ASC, TF.TransTmID ASC) Folder


	OUTER APPLY(	SELECT Top 1 TF.TransDateTime 'First Date'
					FROM QLODS..LKWDTransFact TF  (NOLOCK)
					WHERE TF.LoanNumber = LK.LoanNumber
						AND TF.EventTypeID = 2 -- Status Change
						AND TF.StatusID = 151 -- Stat 41 Final Signoff
					Order By TF.TransDtID ASC, TF.TransTmID ASC) FSO

Where LK.ClosingID BETWEEN 20170000 AND 20170500