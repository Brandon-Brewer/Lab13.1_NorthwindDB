SELECT --month(a.LoanAccessedEnteredDate), count(*)
count(*)
FROM Src.QTweet.LoanAccessedEnteredEvent a
WHERE a.AccessedByCommonId = 2343977
--GROUP BY month(a.LoanAccessedEnteredDate)