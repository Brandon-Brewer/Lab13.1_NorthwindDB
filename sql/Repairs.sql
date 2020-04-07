/****************************************************************
The number of loans with needed repairs
How long does it take to resolve?
****************************************************************/
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	L.LoanNumber
	, ti6958.StatusDateTime		'TI6958 Outstanding Dt'
	, ti6958END.StatusDateTime	'TI6958 Cleared Dt'
	, [TI 6958 TT (days)]		= DATEDIFF(second, ti6958.StatusDateTime, ti6958end.StatusDateTime)/86400.0
	, ti10.StatusDateTime		'TI10 Outstanding Dt'
	--, ti10rec.StatusDateTime	'TI10 Received Dt'
	, ti10END.StatusDateTime	'TI10 Cleared Dt'
	, [TI 10 TT (days)]			= DATEDIFF(second, ti10.StatusDateTime, ti10end.StatusDateTime)/86400.0

FROM QLODS..LKWD L
	OUTER APPLY(
				SELECT TOP 1 tif.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
					AND tif.StatusID = 11 --Outstanding
				ORDER BY tif.StatusDtID ASC, tif.StatusTmID ASC
				) ti10

	OUTER APPLY(
				SELECT TOP 1 tif3.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif3
				WHERE tif3.LoanNumber = L.LoanNumber
					AND tif3.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
					AND tif3.StatusID = 67 --Cleared by Underwriter
				ORDER BY tif3.StatusDtID DESC, tif3.StatusTmID DESC
				) ti10END

		--OUTER APPLY(
		--		SELECT TOP 1 tif5.StatusDateTime
		--		FROM QLODS..LKWDTrackingItemFact tif5
		--		WHERE tif5.LoanNumber = L.LoanNumber
		--			AND tif5.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
		--			AND tif5.StatusID = 56 --Received
		--		ORDER BY tif5.StatusDtID DESC, tif5.StatusTmID DESC
		--		) ti10rec
	
	OUTER APPLY(
				SELECT TOP 1 tif2.StatusDateTime 
				FROM QLODS..LKWDTrackingItemFact tif2
				WHERE tif2.LoanNumber = L.LoanNumber
					AND tif2.TrackingItemID = 6368 --6958 Collateral-Repairs
					AND tif2.StatusID = 11  --Outstanding
				ORDER BY tif2.StatusDtID ASC, tif2.StatusTmID ASC
				) ti6958

	OUTER APPLY(
				SELECT TOP 1 tif4.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif4
				WHERE tif4.LoanNumber = L.LoanNumber
					AND tif4.TrackingItemID = 6368 --6958 Collateral-Repairs
					AND tif4.StatusID = 67 --Cleared by Underwriter
				ORDER BY tif4.StatusDtID DESC, tif4.StatusTmID DESC
				) ti6958END

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	AND COALESCE(ti10.StatusDateTime, ti6958.StatusDateTime) IS NOT NULL
	






----count-------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT DISTINCT
	L.LoanNumber

FROM QLODS..LKWD L
	OUTER APPLY(
				SELECT TOP 1 tif.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
					AND tif.StatusID = 11 --Outstanding
				ORDER BY tif.StatusDtID ASC, tif.StatusTmID ASC
				) ti10
	
	OUTER APPLY(
				SELECT TOP 1 tif2.StatusDateTime 
				FROM QLODS..LKWDTrackingItemFact tif2
				WHERE tif2.LoanNumber = L.LoanNumber
					AND tif2.TrackingItemID = 6368 --6958 Collateral-Repairs
					AND tif2.StatusID = 11  --Outstanding
				ORDER BY tif2.StatusDtID ASC, tif2.StatusTmID ASC
				) ti6958

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	AND ti6958.StatusDateTime IS NOT NULL
	--AND COALESCE(ti10.StatusDateTime, ti6958.StatusDateTime) IS NOT NULL





-------------------turn time-----------------------------------
SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 -- L.LoanNumber
	--, ti6958.StatusDateTime		'TI6958 Outstanding Dt'
	--, ti6958END.StatusDateTime	'TI6958 Cleared Dt'
	 [TI 6958 TT (days)]		= AVG(DATEDIFF(second, ti6958.StatusDateTime, ti6958end.StatusDateTime)/86400.0)
	--, ti10.StatusDateTime		'TI10 Outstanding Dt'
	--, ti10END.StatusDateTime	'TI10 Cleared Dt'
	--, [TI 10 TT (days)]			= DATEDIFF(second, ti10.StatusDateTime, ti10end.StatusDateTime)/86400.0

FROM QLODS..LKWD L
	--OUTER APPLY(
	--			SELECT TOP 1 tif.StatusDateTime
	--			FROM QLODS..LKWDTrackingItemFact tif
	--			WHERE tif.LoanNumber = L.LoanNumber
	--				AND tif.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
	--				AND tif.StatusID = 11 --Outstanding
	--			ORDER BY tif.StatusDtID ASC, tif.StatusTmID ASC
	--			) ti10

	--OUTER APPLY(
	--			SELECT TOP 1 tif3.StatusDateTime
	--			FROM QLODS..LKWDTrackingItemFact tif3
	--			WHERE tif3.LoanNumber = L.LoanNumber
	--				AND tif3.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
	--				AND tif3.StatusID = 67 --Cleared by Underwriter
	--			ORDER BY tif3.StatusDtID DESC, tif3.StatusTmID DESC
	--			) ti10END

	CROSS APPLY(
				SELECT TOP 1 tif2.StatusDateTime 
				FROM QLODS..LKWDTrackingItemFact tif2
				WHERE tif2.LoanNumber = L.LoanNumber
					AND tif2.TrackingItemID = 6368 --6958 Collateral-Repairs
					AND tif2.StatusID = 11  --Outstanding
				ORDER BY tif2.StatusDtID ASC, tif2.StatusTmID ASC
				) ti6958

	CROSS APPLY(
				SELECT TOP 1 tif4.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif4
				WHERE tif4.LoanNumber = L.LoanNumber
					AND tif4.TrackingItemID = 6368 --6958 Collateral-Repairs
					AND tif4.StatusID = 67 --Cleared by Underwriter
				ORDER BY tif4.StatusDtID DESC, tif4.StatusTmID DESC
				) ti6958END

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7  --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	--AND COALESCE(ti10.StatusDateTime, ti6958.StatusDateTime) IS NOT NULL





SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

SELECT
	 -- L.LoanNumber
	--, ti6958.StatusDateTime		'TI6958 Outstanding Dt'
	--, ti6958END.StatusDateTime	'TI6958 Cleared Dt'
	 --[TI 6958 TT (days)]		= AVG(DATEDIFF(second, ti6958.StatusDateTime, ti6958end.StatusDateTime)/86400.0)
	--, ti10.StatusDateTime		'TI10 Outstanding Dt'
	--, ti10END.StatusDateTime	'TI10 Cleared Dt'
	 [TI 10 TT (days)]			= AVG(DATEDIFF(second, ti10.StatusDateTime, ti10end.StatusDateTime)/86400.0)

FROM QLODS..LKWD L
	CROSS APPLY(
				SELECT TOP 1 tif.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif
				WHERE tif.LoanNumber = L.LoanNumber
					AND tif.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
					AND tif.StatusID = 11 --Outstanding
				ORDER BY tif.StatusDtID ASC, tif.StatusTmID ASC
				) ti10

	CROSS APPLY(
				SELECT TOP 1 tif3.StatusDateTime
				FROM QLODS..LKWDTrackingItemFact tif3
				WHERE tif3.LoanNumber = L.LoanNumber
					AND tif3.TrackingItemID = 5 --10 Appraisal - Final Inspection/Repairs*
					AND tif3.StatusID = 67 --Cleared by Underwriter
				ORDER BY tif3.StatusDtID DESC, tif3.StatusTmID DESC
				) ti10END

	--CROSS APPLY(
	--			SELECT TOP 1 tif2.StatusDateTime 
	--			FROM QLODS..LKWDTrackingItemFact tif2
	--			WHERE tif2.LoanNumber = L.LoanNumber
	--				AND tif2.TrackingItemID = 6368 --6958 Collateral-Repairs
	--				AND tif2.StatusID = 11  --Outstanding
	--			ORDER BY tif2.StatusDtID ASC, tif2.StatusTmID ASC
	--			) ti6958

	--CROSS APPLY(
	--			SELECT TOP 1 tif4.StatusDateTime
	--			FROM QLODS..LKWDTrackingItemFact tif4
	--			WHERE tif4.LoanNumber = L.LoanNumber
	--				AND tif4.TrackingItemID = 6368 --6958 Collateral-Repairs
	--				AND tif4.StatusID = 67 --Cleared by Underwriter
	--			ORDER BY tif4.StatusDtID DESC, tif4.StatusTmID DESC
	--			) ti6958END

WHERE 1=1
	AND L.DeleteFlg = 0
	AND L.ReverseFlg = 0
	AND L.LoanPurposeID <> 7 --Purchase
	AND L.Stat21ID IS NOT NULL
	AND COALESCE(L.ClosingID, L.FalloutID) BETWEEN 20170100 AND 20170700
	--AND COALESCE(ti10.StatusDateTime, ti6958.StatusDateTime) IS NOT NULL
