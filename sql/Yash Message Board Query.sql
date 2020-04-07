Set transaction isolation level read uncommitted

--This query is to show loans that had a CCS/SPS respond to a client from the previous day 


Select * from
(select
count(T.LoanNumber) 'Number of Loans'
--,p.ThreadId
--, case when A.createddate is null then 'TM Post' 
--            when A.fullnamefirstlast is null then 'Client' 
--     else 'Error' end 'Who Posted'
--,A.CreatedDate as 'Client post date'
--,Em.FullNameFirstLast 'Hunt TM'
,convert(date,p.Createddate) as d
--,p.createddate as 'Hunt Response Date'
--,EM.opsdirector
--,Em.OpsDVP
,LPD.LoanPurpose
,LCD.ChannelName
,PBAT.ProductBucket
--,case when datediff(hour,A.createddate, P.createddate) > 24 then CONVERT(VARCHAR(5),datediff(day, A.createddate, P.createddate)) + ' days'
       --When datediff(hour,A.createddate, P.createddate) is null then 'No Client Post Time'
-- else CONVERT(VARCHAR(2),datediff(minute, A.createddate, P.createddate)/60) + ':' + CONVERT(VARCHAR(2),(datediff(minute, A.createddate, P.createddate)%60))
--  + ' Hours' end as 'time'
,AVG(DATEDIFF(HOUR, A.CreatedDate, P.createddate)) 'Response Time'

From
       SRC.MessageBoard.Post P
       inner join SRC.MessageBoard.poster Pr on Pr.posterid = P.PosterId
       Left join QLODS..Employeemaster EM on EM.commonid = Pr.PosterReferenceId
       inner join SRC.messageboard.Thread T on T.ThreadId = P.ThreadId
       inner join QLODS..LKWD L on L.loannumber = T.LoanNumber
       inner join QLODS..LoanPurposeDim LPD on LPD.LoanPurposeID = L.LoanPurposeID
       inner join QLODS..LoanChannelDim LCD on LCD.LoanChannelID = L.LoanChannelGroupID
       inner join Reporting..vwProductBuckets PBAT on PBAT.ProductId = L.ProductID
outer apply (Select top 1 EM2.FullNameFirstLast, P2.CreatedDate, P2.updateddate ---Finds the last time a client posted on the message board.
                                  From SRC.Messageboard.post P2
                                  inner join SRC.MessageBoard.poster PR2 on PR2.PosterId = P2.posterid
                                  left join QLODS..employeemaster EM2 on EM2.commonid =  PR2.PosterReferenceId
                                  inner join SRC.messageboard.thread T2 on T2.ThreadId = P2.ThreadId
                                  where 
                                  T2.loannumber = T.loannumber
                                  And p.threadid = p2.threadid --same thread as the thread the TM posted on yesterday
                                  and p2.createddate < p.CreatedDate 
                                  and EM2.FullNameFirstLast is null --client post
                                  order by p2.CreatedDate desc) A
--Outer apply (Select top 1
--                                From QLODS..LKWDTrackingItemFact
--                                where 
                                  
       where EM.opsdvp like '%Steven Chandler%' or EM.opsdvp like '%Ebony Stone%' or EM.opsdvp like '%Lashandra Sartor%' or Em.opsdvp like '%Tom Hrovat%' or EM.opsdvp Like '%Wendy Maurer%' --TM population we want
       Group by  LPD.LoanPurpose, LCD.ChannelName, PBAT.[ProductBucket], convert(date,p.Createddate)
              ) b ---subquery was to convert the createddate to a date rather than date time. 
                                  where
                                         b.d between '2017-05-01' and '2017-08-01'
