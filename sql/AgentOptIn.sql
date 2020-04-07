USE [Reporting]
GO

/****** Object:  View [dbo].[vw_QText_QNotifierHistory]    Script Date: 9/5/2017 8:38:31 AM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO



--CREATE VIEW [dbo].[vw_QText_QNotifierHistory]   
--AS  
 
WITH ConversationOwner AS(
					      SELECT REPLACE(REPLACE(REPLACE(REPLACE(em.TelephoneNumber,'(',''), ')','') ,' ','') ,'-','') TelephoneNumber
							    ,em.FullNameFirstLast 
	                            ,em.CommonID
					      FROM qlods..EmployeeMaster em WITH(NOLOCK)
					      WHERE em.EmpStatus = 'A'
					     ) /*Conversation Owner*/
	,Interactor AS(
			       SELECT srs.SourceValue CommonID
		                 ,srs.MessageSentId
					     ,em.FullNameFirstLast
	               FROM src.Messenger.SourceReferenceSent srs WITH(NOLOCK)
			       JOIN qlods..EmployeeMaster em WITH(NOLOCK)
	                   ON srs.SourceValue = em.CommonID
	               WHERE ((srs.SourceName = 'CSA' AND srs.SourceType = 'SenderCommonId') OR 
				          (srs.SourceName = '201011' AND srs.SourceType = 'CommonId'))
		          ) /*"On behalf of" team member*/
    ,SRR AS(
			SELECT srr.MessageReceivedId MessageReceivedId
			      ,JSON_VALUE(srr.SourceValue, '$.LoanNumber') LoanNumber			         
			      ,ROW_NUMBER() OVER(PARTITION BY srr.MessageReceivedId ORDER BY srr.CreateDate) rnk			
	        FROM src.Messenger.SourceReferenceReceived srr WITH(NOLOCK)
	        WHERE srr.SourceName = 'mobius'
	            AND srr.SourceType = 'ClientInfo'
				AND JSON_VALUE(srr.SourceValue, '$.TransactionStatus') = 'InProcess'
				AND JSON_VALUE(srr.SourceValue, '$.LoanStatus') BETWEEN 21 AND 41
		   ) /*To parse out Loan Number for message received, and chose one from loans that are currently in process*/

SELECT * FROM 
(SELECT DISTINCT 
coa.*,
em.FullNameFirstLast TeamMember
,em.CommonID 
,emTL.FullNameFirstLast TeamLeader
,emDir.FullNameFirstLast Director
,emDVP.FullNameFirstLast DVP
      --,tmh.MessageId MessageId
	  ,tmh.LoanNumber LoanNumber
	  --,CASE WHEN tmh.MessageAction = 'replied' AND tmh.rnk = 1 
	  --      THEN 'initiated'
			--ELSE tmh.MessageAction
			--END MessageAction
	  ,CAST(tmh.MessageDt AS DATE) MessageDt
	  ,tmh.ExternalClientPhoneNumber ExternalClientPhoneNumber
	  ,tmh.ConversationTM ConversationTM
	  ,tmh.ConversationTMCommonID ConversationTMCommonID 
	  ,tmh.InteractionTM InteractionTM
	  ,tmh.InteractionTMCommonID InteractionTMCommonID
	  ,RANK() OVER(PARTITION BY tmh.ExternalClientPhoneNumber ORDER BY tmh.MessageDt) rnk
FROM(SELECT base.*
	       ,RANK() OVER(PARTITION BY ISNULL(base.LoanNumber, base.ExternalClientPhoneNumber) ORDER BY base.MessageDt) rnk
     FROM(SELECT tmh.MessageId MessageId
	            ,ms.LoanNumber LoanNumber
	            ,tmh.[Action] MessageAction
	            ,tmh.CreateDate MessageDt
	            ,tmh.FromPhoneNumber ExternalClientPhoneNumber
	            ,ConversationOwner.FullNameFirstLast ConversationTM
	            ,ConversationOwner.CommonID ConversationTMCommonID
	            ,Interactor.FullNameFirstLast InteractionTM
	            ,Interactor.CommonID InteractionTMCommonID
          FROM src.Messenger.TextMessageHistory tmh WITH(NOLOCK)
		  LEFT JOIN src.Messenger.MessageSent ms WITH(NOLOCK) /*For Loan Number and join to TextMessageHistory*/
	          ON tmh.MessageId = ms.ReferenceMessageId
		      AND tmh.FromPhoneNumber = ms.PhoneNumber
		  LEFT JOIN ConversationOwner
		      ON tmh.ToPhoneNumber = ConversationOwner.TelephoneNumber
		  LEFT JOIN Interactor 
		      ON ms.MessageSentId = Interactor.MessageSentId
          WHERE tmh.[Action] = 'replied'	
		  AND EXISTS (SELECT 1 FROM src.Messenger.SourceReferenceSent srs WITH(NOLOCK)
							 JOIN src.Messenger.MessageSent ms WITH(NOLOCK)
								ON srs.MessageSentId = ms.MessageSentId
							 WHERE (srs.SourceName = 'AgentInsight' AND srs.SourceType = 'CommonId')
								 AND ms.ReferenceMessageId = tmh.MessageId
				      )

          UNION ALL

          SELECT tmh.MessageId MessageId
                ,srr.LoanNumber LoanNumber
	            ,tmh.[Action] MessageAction
	            ,tmh.CreateDate MessageDt
	            ,tmh.FromPhoneNumber ExternalClientPhoneNumber	
	            ,ConversationOwner.FullNameFirstLast ConversationTM
	            ,ConversationOwner.CommonID ConversationTMCommonID
	            ,NULL InteractionTM
	            ,NULL InteractionTMCommonID
		  FROM src.Messenger.TextMessageHistory tmh WITH(NOLOCK)
          LEFT JOIN SRR 
	          ON tmh.MessageId = srr.MessageReceivedId
	          AND srr.rnk = 1
          LEFT JOIN ConversationOwner
		      ON tmh.ToPhoneNumber = ConversationOwner.TelephoneNumber
          WHERE tmh.[action] IN ('received','soft close')
		       AND EXISTS (SELECT 1 FROM [SRC].[Messenger].[SourceReferenceReceived] srr
						            WHERE (srr.SourceName = 'PersonHub' AND srr.SourceType = 'AgentInfo')
							        AND CAST(srr.MessageReceivedId AS VARCHAR(50)) = tmh.MessageId
		                  )
)base
)tmh

JOIN [SRC].[Messenger].[ClientOpt_Audit] coa WITH(NOLOCK)
	ON CAST(coa.MessageReceivedId AS VARCHAR(20 )) = tmh.MessageId
		AND coa.IsOptIn = 1
JOIN qlods..EmployeeMaster em WITH(NOLOCK)
	ON tmh.ConversationTMCommonID = em.CommonID
	AND em.CommonID != 2008031 /*Anil Pundhir*/
JOIN qlods..EmployeeMaster emTL WITH(NOLOCK)
	ON em.TeamLeaderCommonID = emTL.CommonID
JOIN qlods..EmployeeMaster emDir WITH(NOLOCK)
	ON emTL.TeamLeaderCommonID = emDir.CommonID
JOIN qlods..EmployeeMaster emDVP WITH(NOLOCK)
	ON emDir.TeamLeaderCommonID = emDVP.CommonID
) tmh
WHERE CAST(tmh.MessageDt AS DATE) = '9/21/2017'

GO


