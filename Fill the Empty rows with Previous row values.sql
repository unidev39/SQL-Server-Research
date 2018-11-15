---8Square Ozopay Staging 

SELECT 
				ROW_NUMBER() over(order by CreatedDate desc) as ID,
				PaymentDate, 
				CCPName,
				TerminalId,
				UserId,
				TxnId,
				MoneyIn,
				MoneyOut,
				WalletBalance,
				case when CONVERT(NVARCHAR,CreditLimit) = '' then null else CONVERT(NVARCHAR,CreditLimit)  end as CreditLimit,
				TransactionType,
				ProductCode,
				Commission,
				GSTOnCommission,
				Remarks 
    INTO #Temp								
	FROM #Transaction		
    OPTION(RECOMPILE);

	SELECT 
				ID,
				PaymentDate, 
				CCPName,
				TerminalId,
				UserId,
				TxnId,				
				CONVERT(NVARCHAR,MoneyIn) as MoneyIn,
				CONVERT(NVARCHAR,MoneyOut) as MoneyOut,
				CONVERT(NVARCHAR, isnull(MAX(WalletBalance) OVER (PARTITION BY C),0)) AS WalletBalance,				
				CONVERT(NVARCHAR,MAX(CreditLimit) OVER (PARTITION BY D)) AS CreditLimit,
				TransactionType,
				ProductCode,
				CONVERT(NVARCHAR,Commission) as Commission,
				CONVERT(NVARCHAR,GSTOnCommission) as GSTOnCommission,
				Remarks 
	FROM 
			(
			 SELECT 
			           ID,
					   PaymentDate, 
				       CCPName,
				       TerminalId,
				       UserId,
				       TxnId,
					   WalletBalance,
					   CreditLimit,
					   MoneyIn,
					   MoneyOut,
			           C= COUNT(WalletBalance) OVER (ORDER BY ID DESC), 
					   D= COUNT(CreditLimit) OVER (ORDER BY ID DESC) ,
					   TransactionType,
				       ProductCode,
				        Commission,
				        GSTOnCommission,
				        Remarks 
			 FROM #Temp
			) A 
	ORDER BY ID
