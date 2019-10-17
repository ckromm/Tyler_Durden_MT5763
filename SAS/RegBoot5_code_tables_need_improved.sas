/*The final function should output results to an RTF file using the Output Delivery System. */
/*This should have 95% confidence intervals for the mean (???), the mean estimate for each parameter */
/*and plots of the distributions of the bootstrap parameters. It need only work for one covariate.*/
/**/
/*I'm going to try to code a SAS-optimized bootstrapping method for a confidence*/
/*interval for the parameter estimates. I will then need to look at how much faster it is.*/
/*The method is basically to combine the regboot macro with the efficient bootstrapping method. */


%macro regBoot(NumberOfLoops, DataSet, XVariable, YVariable);

/*Number of rows in my dataset*/
 	data _null_;
  	set &DataSet NOBS=size;
  	call symput("NROW",size); /*reminder that this assigns a variable to a name within the macro*/
 	stop; /*exits the data procedure*/
 	run;

/*Create our samples of same size as original dataset*/
 	proc surveyselect data=&DataSet out=outboot seed=2345
    method=urs noprint sampsize=&NROW outhits rep=&NumberOfLoops; 
    run;

/*Conduct a regression on each randomised sample in the dataset and get parameter estimates*/
	proc reg data=outboot outest=bootEstimates  noprint;
	Model &YVariable=&XVariable;
    by replicate; 
  	run;
	quit;

/*Obtain quantiles for each, starting with the slope parameter.*/
  	proc univariate data=bootEstimates noprint;
    var &XVariable;
    output out=regBootSlopeCI pctlpts=2.5, 97.5 pctlpre=CI mean=Mean; 
  	run;

	proc univariate data=bootEstimates noprint;
    var Intercept;
    output out=regBootInterceptCI pctlpts=2.5, 97.5 pctlpre=CI mean=Mean; 
  	run;

	proc template;
	define statgraph Graph1;
	dynamic _INTERCEPT;
	begingraph;
	   entrytitle halign=center 'Frquency of Bootstrapped Estimate for the Intercept Parameter';
	   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
	      layout overlay / yaxisopts=( label=('Frequency'));
	         histogram _INTERCEPT / name='histogram' datatransparency=0.3 binaxis=false fillattrs=(color=CX6371AD ) outlineattrs=(color=CX000000 pattern=SOLID thickness=1 );
	      endlayout;
	   endlayout;
	endgraph;
	end;
	run;

	proc template;
	define statgraph Graph2;
	dynamic _&XVariable;
	begingraph;
	   entrytitle halign=center 'Frquency of Bootstrapped Estimate for the Slope Parameter';
	   layout lattice / rowdatarange=data columndatarange=data rowgutter=10 columngutter=10;
	      layout overlay / yaxisopts=( label=('Frequency'))/ xaxisopts=( label=('Slope Parameter'));
	         histogram _&XVariable / name='histogram' datatransparency=0.3 binaxis=false fillattrs=(color=CX6371AD ) outlineattrs=(color=CX000000 pattern=SOLID thickness=1 );
	      endlayout;
	   endlayout;
	endgraph;
	end;
	run;

/*Output tables and graphs into an RTF*/
	ods rtf;

		proc print data=regBootInterceptCI;
		title 'Confidence Interval and Mean for the Intercept Parameter Obtained from Bootstrapping';
		run;

		proc print data=regBootSlopeCI;
		title 'Confidence Interval and Mean for the Slope Parameter Obtained from Bootstrapping';
		label mean = 'Mean' CI2_5 = 'Lower Limit' CI97_5 = 'Upper Limit';
		run;

/*Create plots of the estimates.*/
		proc gchart data=bootEstimates; 
		title 'Frequency of Bootstrapped Estimate for the Slope Parameter';
	    vbar &Xvariable;
	  	run;

		proc gchart data=bootEstimates; 
		title 'Frequency of Bootstrapped Estimate for the Intercept Parameter';
		vbar Intercept;
	  	run;

		proc sgrender data=bootestimates template=Graph1;
		dynamic _INTERCEPT="INTERCEPT";
		run;

		proc sgrender data=bootestimates template=Graph2;
		dynamic _&XVariable="&XVariable";
		run;
	ods rtf close;

%mend;
%regBoot(NumberOfLoops = 1000, DataSet = SAS_5763.regData, XVariable = x, YVariable = y);














