SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

IF OBJECT_ID('tempdb..#stat20loans','U') IS NOT NULL
       DROP TABLE #stat20loans

DROP TABLE #QualifyingLoans
DROP TABLE #Stat21
DROP TABLE #Stat33
DROP TABLE #Stat35
DROP TABLE #Stat40

SELECT lk.LoanNumber, lk.Stat20ID, lk.Stat20TmID, lk.Stat21ID, lk.Stat21TmID, lk.Stat33ID, lk.Stat33TmID, lk.Stat35ID, lk.Stat35TmID, lk.Stat40ID, lk.Stat40TmID, 
              ltf.LTV, ltf.DTI, ltf.QualFICO, ltf.LoanAmount

INTO #stat20loans

FROM QLODS..LKWD lk (NOLOCK)
       INNER JOIN Reporting.dbo.vwProductBuckets pb (NOLOCK) ON pb.ProductID = lk.ProductID
              AND pb.ProductBucket = 'Conventional'
              AND pb.JumboFlg = 0
              AND pb.ProductDescription not like '%home possible%'
              AND pb.ProductDescription not like '%fred%'

       INNER JOIN QLODS..loanchannelgroupDIM lcg (NOLOCK) ON lcg.LoanChannelGroupID = lk.LoanChannelGroupID
              AND lcg.FriendlyName not like '%schwab%'
              AND lcg.FriendlyName not like '%cadillac%'
              AND 
                     (REPLACE(lcg.FriendlyName,' ','') NOT LIKE '%ssharp%'
                     OR REPLACE(lcg.FriendlyName,' ','') NOT LIKE '%SameServicerHarp%')
       
       LEFT JOIN QLODS..LKWDTransFact ltf (NOLOCK) ON ltf.Loannumber = lk.loannumber
              AND ltf.TransDtID = lk.Stat20ID
              AND ltf.TransTmID = lk.Stat20TmID
              AND ltf.EventtypeID = 2
              AND ltf.StatusID = 119 --status 20

WHERE lk.Stat20ID Between 20170100 AND 20170131
       AND lk.employeeloanflg = 0
       AND lk.LoanPurposeID = 7 --Refi
       AND lk.Selfemployflg = 0
       AND lk.DeleteFlg = 0
       AND lk.ReverseFlg = 0




Select s20.*

INTO #qualifyingloans

FROM #stat20loans s20

       OUTER APPLY(
                           SELECT TOP 1 sd.StatusDescription
                           FROM QLODS..LKWDTrackingItemFact tif (NOLOCK)
                                  INNER JOIN QLODS..LKWDTrackingItemStatusDim sd (NOLOCK) ON sd.StatusID = tif.StatusID 
                           WHERE tif.Loannumber = s20.LoanNumber
                                  AND tif.trackingitemid = 2485 --TI 1727 Folder Incomplete
                                  AND tif.StatusDtID <= s20.Stat20ID
                                  AND CASE WHEN tif.StatusDtID = s20.Stat20ID THEN 
                                                CASE WHEN tif.StatusTmID <= s20.Stat20TmID THEN 1 ELSE 0 END
                                         ELSE 1 END = 1
                                  AND tif.Deleteflg = 0
                           
                           ORDER BY tif.StatusDtID Desc, tif.StatusTmID DESC
                           ) TI1727



WHERE isnull(TI1727.StatusDescription, 'cancelled') like 'cancelled'





SELECT Q.*
       , FirstStat21ID            = FirstSt21.TransDtID
       , FirstStat21TmID   = FirstSt21.TransTmID
INTO #Stat21
FROM #QualifyingLoans Q
       OUTER APPLY (
                           SELECT TOP 1 TransDtID
                                  , TransTmID
                           FROM QLODS.dbo.LKWDTransFact
                           LTF (NOLOCK)
                           WHERE LTF.LoanNumber = Q.LoanNumber
                          AND LTF.EventTypeID = 2
                           AND LTF.StatusID = 76  -- Put StatusID From StatusDim here, ex. StatusID = 76 is Stat 21
                           AND LTF.DeleteFlg = 0
                           ORDER BY LTF.TransDtID ASC
                                  , LTF.TransTmID ASC
                 ) FirstSt21


SELECT S.*
       , FirstStat33ID            = FirstSt33.TransDtID
       , FirstStat33TmID   = FirstSt33.TransTmID
INTO #Stat33
FROM #Stat21 S
       OUTER APPLY (
                           SELECT TOP 1 TransDtID
                                  , TransTmID
                           FROM QLODS.dbo.LKWDTransFact
                           LTF (NOLOCK)
                           WHERE LTF.LoanNumber = S.LoanNumber
                          AND LTF.EventTypeID = 2
                           AND LTF.StatusID =  117
                           AND LTF.DeleteFlg = 0
                           ORDER BY LTF.TransDtID ASC
                                  , LTF.TransTmID ASc
                 ) FirstSt33




SELECT S.*
       , FirstStat35ID            = FirstSt35.TransDtID
       , FirstStat35TmID   = FirstSt35.TransTmID
INTO #Stat35
FROM #Stat33 S
       OUTER APPLY (
                           SELECT TOP 1 TransDtID
                                  , TransTmID
                           FROM QLODS.dbo.LKWDTransFact
                           LTF (NOLOCK)
                           WHERE LTF.LoanNumber = S.LoanNumber
                           AND LTF.EventTypeID = 2
                           AND LTF.StatusID =  83
                           AND LTF.DeleteFlg = 0
                           ORDER BY LTF.TransDtID ASC
                                  , LTF.TransTmID ASc
                 ) FirstSt35




SELECT S.*
       , FirstStat40ID            = FirstSt40.TransDtID
       , FirstStat40TmID   = FirstSt40.TransTmID
INTO #Stat40
FROM #Stat35 S
       OUTER APPLY (
                           SELECT TOP 1 TransDtID
                                  , TransTmID
                           FROM QLODS.dbo.LKWDTransFact
                           LTF (NOLOCK)
                           WHERE LTF.LoanNumber = S.LoanNumber
                           AND LTF.EventTypeID = 2
                           AND LTF.StatusID =  181
                           AND LTF.DeleteFlg = 0
                           ORDER BY LTF.TransDtID ASC
                                  , LTF.TransTmID ASc
                 ) FirstSt40





SELECT * FROM #Stat40
