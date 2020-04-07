-- Pull all Refi Rocket loans that hit Stat 41
DROP TABLE IF EXISTS #RefiRocketLoans

SELECT LK.LoanNumber
    , LK.Stat41Dt
    , LK.Stat43Dt
    , LK.Stat41ID
    , LK.Stat41TmID
    , LK.Stat43ID
    , LK.Stat43TmID
INTO #RefiRocketLoans
FROM QLODS.dbo.LKWD
LK (NOLOCK)
INNER JOIN BILoan.Lead.vw_RocketLeads
R                   ON R.LoanNumber = LK.LoanNumber
WHERE LK.DeleteFlg = 0
AND LK.ReverseFlg = 0
AND LK.LoanPurposeID = 7
AND LK.Stat41ID IS NOT NULL


DROP TABLE IF EXISTS #Swiffer

SELECT R.*
    , TIF.TrackingItemID
    , TIF.TrackingSeqNum
    , TIF.StatusID
    , CBUDtID                   = TIF.StatusDtID
    , CBUTmID                   = TIF.StatusTmID
    , TIF.StatusSeqNum
    , TIF.StatusUserID
    , EM.FirstName
	, EM.Preferredname
	, EM.LastName
	, EM.PreferredLastName
	, Extension                 = REPLACE(RIGHT(EM.TelephoneNumber,6),'-','')
    , SwifferCount              = COUNT(TIF.StatusSeqNum) OVER(PARTITION BY R.LoanNumber)
INTO #Swiffer
FROM #RefiRocketLoans
R
LEFT JOIN QLODS.dbo.LKWDTrackingItemFact
TIF (NOLOCK)            ON R.LoanNumber = TIF.LoanNumber
                        AND TIF.TrackingItemID = 5004
                        AND TIF.StatusID = 67
                        AND TIF.DeleteFlg = 0
                        AND TIF.StatusDtID BETWEEN R.Stat41ID AND R.Stat43ID
                        AND CASE WHEN TIF.StatusDtID = R.Stat41ID AND TIF.StatusTmID < R.Stat41TmID THEN 0
                                WHEN TIF.StatusDtID = R.Stat43ID AND TIF.StatusTmID > R.Stat43TmID THEN  0
                                ELSE 1 END = 1
LEFT JOIN QLODS.dbo.EmployeeMaster
EM (NOLOCK)             ON EM.EmployeeDimID = TIF.StatusUserID


DROP TABLE IF EXISTS #SwifferReasons

SELECT S.*
	, StatusDate			= DATEADD(SECOND,Reporting.dbo.fn_GetTimeID(SR.[Time])-1,SR.[Date])
	, StatusDtID			= Reporting.dbo.fn_GetDateID(SR.[Date])
	, StatusTmID			= Reporting.dbo.fn_GetTimeID(SR.[Time])
	, SR.[Communication Type]
	, SR.[Contact Type]
	, SR.[Contact Reason]
	, SR.[Contact Result]
	, SR.[Problem Reason]
INTO #SwifferReasons
FROM #Swiffer
S
INNER JOIN BISandboxWrite.jwoz.SwifferReasons		-- Table built from AMP Swiffer Query
SR			ON S.LoanNumber = CONVERT(VARCHAR(10),CAST(SR.[Loan Number] AS BIGINT))	-- Match on Loan
			AND S.CBUDtID = Reporting.dbo.fn_GetDateID(SR.[Date])	-- Same date as 5308Cleared by Underwriter
			AND S.CBUTmID <= Reporting.dbo.fn_GetTimeID(SR.[Time])	-- On or after 5308 Cleared by Underwriter
			AND S.Extension = RTRIM(LTRIM(RIGHT(SR.[User],LEN(SR.[User]) - CHARINDEX('-', SR.[User])))) -- Match on user by looking at phone number first
			AND (
					S.FirstName = RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))			-- Then First Name
					OR S.Preferredname = RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))
				)
			AND (	-- Or Last Name (sometimes the last names are truncated in the swiffer report so look to see if its similar
					S.LastName = RTRIM(LTRIM(REPLACE(REPLACE(SR.[User],RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))+' ',''),'-'+RTRIM(LTRIM(RIGHT(SR.[User],LEN(SR.[User]) - CHARINDEX('-', SR.[User])))),'')))
					OR S.Preferredlastname = RTRIM(LTRIM(REPLACE(REPLACE(SR.[User],RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))+' ',''),'-'+RTRIM(LTRIM(RIGHT(SR.[User],LEN(SR.[User]) - CHARINDEX('-', SR.[User])))),'')))
					OR CHARINDEX(RTRIM(LTRIM(REPLACE(REPLACE(SR.[User],RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))+' ',''),'-'+RTRIM(LTRIM(RIGHT(SR.[User],LEN(SR.[User]) - CHARINDEX('-', SR.[User])))),''))),S.LastName) > 0
					OR CHARINDEX(RTRIM(LTRIM(REPLACE(REPLACE(SR.[User],RTRIM(LTRIM(LEFT(SR.[User],CHARINDEX(' ',SR.[User]))))+' ',''),'-'+RTRIM(LTRIM(RIGHT(SR.[User],LEN(SR.[User]) - CHARINDEX('-', SR.[User])))),''))),S.Preferredlastname) > 0
				)


DROP TABLE IF EXISTS #CorrectReasons1

SELECT *
	, Matchup		= CASE WHEN CBUTmID = StatusTmID THEN 0
						WHEN StatusDtID IS NULL THEN 0
						ELSE ROW_NUMBER() OVER(PARTITION BY LoanNumber, StatusDtID, StatusTmID ORDER BY CBUDtID DESC, CBUTmID DESC)
						END -- If the reason is entered at the same time as CBU then use that reason, if there is no reason still keep the record
								-- then order by to pull the most recent CBU for each reason.
INTO #CorrectReasons1
FROM #SwifferReasons
ORDER BY LoanNumber
	, CBUDtID
	, CBUTmID


DROP TABLE IF EXISTS #CorrectReasons2

SELECT C1.*
INTO #CorrectReasons2
FROM #CorrectReasons1
C1
INNER JOIN (
				SELECT LoanNumber
					, TrackingItemID
					, TrackingSeqNum
					, StatusDtID
					, StatusTmID
					, [Communication Type]
					, [Contact Type]
					, [Contact Reason]
					, [Contact Result]
					, [Problem Reason]
					, MinMatchupNum				= MIN(Matchup) -- Get the match based on above
				FROM #CorrectReasons1
				WHERE StatusDtID IS NOT NULL
				GROUP BY LoanNumber
					, TrackingItemID
					, TrackingSeqNum
					, StatusDtID
					, StatusTmID
					, [Communication Type]
					, [Contact Type]
					, [Contact Reason]
					, [Contact Result]
					, [Problem Reason]
			) C2 ON C1.LoanNumber = C2.LoanNumber
					AND C1.TrackingItemID = C2.TrackingItemID
					AND C1.TrackingSeqNum = C2.TrackingSeqNum
					AND C1.StatusDtID = C2.StatusDtID
					AND C1.StatusTmID = C2.StatusTmID
					AND C1.[Communication Type]= C2.[Communication Type]
					AND C1.[Contact Type] = C2.[Contact Type]
					AND C1.[Contact Reason]	= C2.[Contact Reason]
					AND C1.[Contact Result]	= C2.[Contact Result]
					AND C1.[Problem Reason]	= C2.[Problem Reason]
					AND C1.Matchup = C2.MinMatchupNum


DROP TABLE IF EXISTS #SwifferFinal

SELECT S.LoanNumber
	, S.Stat41Dt
	, S.Stat43Dt
    , SwifferInd                    = CASE WHEN S.SwifferCount > 0 THEN 'Swiffer' ELSE 'No Swiffer' END
    , S.SwifferCount
    , SwifferClearedDate            = DATEADD(SECOND, S.CBUTmID-1, CONVERT(VARCHAR(10), S.CBUDtID, 112))
	, [Communication Type]          = ISNULL(C.[Communication Type],' ')
	, [Contact Reason]              = ISNULL(C.[Contact Reason],' ')
	, [Contact Result]              = ISNULL(C.[Contact Result],' ')
	, [Contact Type]                = ISNULL(C.[Contact Type],' ')
	, [Problem Reason]              = ISNULL(C.[Problem Reason],' ')
INTO #SwifferFinal
FROM #Swiffer
S
LEFT JOIN #CorrectReasons2
C			ON S.LoanNumber = C.LoanNumber
			AND S.TrackingItemID = C.TrackingItemID
			AND S.TrackingSeqNum = C.TrackingSeqNum
			AND S.CBUDtID = C.CBUDtID
			AND S.CBUTmID = C.CBUTmID


SELECT *
FROM #SwifferFinal