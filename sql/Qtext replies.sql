/****** Script for SelectTopNRows command from SSMS  ******/
SELECT
      [ConversationTM]
      ,[InteractionTM]
	  --,COUNT(LoanNumber)
  FROM [Reporting].[dbo].[vw_QText_QNotifier]
  WHERE MessageDtID = 20171211
	AND MessageAction = 'replied'