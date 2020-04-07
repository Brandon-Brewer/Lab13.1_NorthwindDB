SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED  --Avoids angry engineers 

--Drops a temp table if one exists
--IF OBJECT_ID('tempdb..#StartingPop','U') IS NOT NULL
       --DROP TABLE #StartingPop

SELECT 
	LK.LoanNumber
	, LK.ClosingDt
	, [15 days after 20] = lk.Stat20Dt + 15
	, [20-43 TT]	=	DATEDIFF(SECOND, DATEADD(SECOND, s20.tm-1, CONVERT(VARCHAR(MAX), CAST(s20.id AS VARCHAR(10)),112))
										, DATEADD(SECOND, s43.tm43-1, CONVERT(VARCHAR(MAX), CAST(s43.id43 AS VARCHAR(10)),112)))/86400.0
	, [MOONSHOT]	=	CASE WHEN (DATEDIFF(SECOND, DATEADD(SECOND, s20.tm-1, CONVERT(VARCHAR(MAX), CAST(s20.id AS VARCHAR(10)),112))
										, DATEADD(SECOND, s43.tm43-1, CONVERT(VARCHAR(MAX), CAST(s43.id43 AS VARCHAR(10)),112)))/86400.0) 
											<= 15 THEN 1 ELSE 0 END


FROM QLODS..LKWD LK
	OUTER APPLY (
					SELECT TOP 1
						id =		ltf.TransDtID
						, tm =		ltf.TransTmID
					FROM QLODS..LKWDTransFact ltf
					WHERE ltf.LoanNumber = LK.LoanNumber
						AND ltf.EventtypeID = 2
						AND ltf.StatusID = 119 --stat 20
						AND ltf.Deleteflg = 0
					ORDER BY ltf.TransDtID, ltf.TransTmID
				)s20

	OUTER APPLY (
					SELECT TOP 1
						id43 =		Ltf.TransDtID
						, tm43 =	ltf.TransTmID
					FROM QLODS..LKWDTransFact ltf
					WHERE ltf.LoanNumber = LK.LoanNumber
						AND ltf.EventtypeID = 2
						AND ltf.StatusID = 133 --stat 43
						AND ltf.Deleteflg = 0
					ORDER BY ltf.TransDtID, ltf.TransTmID
				)s43


WHERE	LK.ClosingID BETWEEN 20170200 AND 20170230
		AND LK.LoanPurposeID = 7 --Refi
		AND LK.ReverseFlg = 0
		AND LK.DeleteFlg = 0