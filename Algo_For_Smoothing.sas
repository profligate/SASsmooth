/* Reading in nonsmoothed data */
proc sql;
create table work0 as 
  select * 
  from mylib.SNLIBISlaglead
	order by Institution, Date;
quit;

data work;
	set work0;
run;

%macro smooth;
%let variables=CShares_Outstanding_c Core_Deposits_c
		Dividend_Yield_c Franchise_Value_c Goodwill_c Market_Value_of_Equity_c
		Market_to_Book_c NPAs_Assets_c Net_Interest_Margin_c NonintExpense_Assets_c
		NonintExpense_Revenue_c NonintIncome_Assets_c NonintIncome_Revenue_IBIS 
		Price_per_share_c ROA_c Tier_1_c Total_Assets_c Total_Deposits_c
		Total_Dividends_Paid_SNL Total_Gross_Loans_c Total_Liabilities_c Total_Net_Loans_c;
%local i vars;
%do i=1 %to %sysfunc(countw(&variables));
	%let vars = %scan(&variables,&i);
	data work(drop=&vars._test:);
		set work;
		by Institution Date;
		&vars._test = mean(Lag_&vars.,Lead_&vars.);
		&vars._test_high = &vars._test*1.5;
		&vars._test_low = &vars._test*0.5;
		&vars. = ifn(abs(&vars.) > abs(&vars._test_high) 
			or abs(&vars.) < abs(&vars._test_low), &vars._test, &vars);
		/* Not smoothing unless t-1 and t+1 available */
		if last.date=1 or first.date=1 then &vars. = &vars.;
		/* varflag included to check which obs are changed */
		if &vars = &vars._test then varflag&i=1;
	run;
%end;
%mend smooth;
%smooth;

/* Dropping vars and creating full dataset */
data SNLIBIS_c(drop=Lag_: Lead_: varflag:);
	set work;
run;

/* Comparing pre to post */
proc compare base=work0 compare=SNLIBIS_c;
run;

