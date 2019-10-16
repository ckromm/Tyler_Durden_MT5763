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

/*Obtain quantiles for each, starting with the slope parameter.*/
  	proc univariate data=bootEstimates noprint;
    var &XVariable;
    output out=regBootSlopeCI pctlpts=2.5, 97.5 pctlpre=CI; 
  	run;

	proc univariate data=bootEstimates noprint;
    var Intercept;
    output out=regBootInterceptCI pctlpts=2.5, 97.5 pctlpre=CI; 
  	run;

/*Place them into a table for output.*/
	data ResultHolder;
    set regBootInterceptCI regBootSlopeCI;
  	run;

/*Create plots of the estimates.*/
	proc gchart data=bootEstimates; 
    vbar &Xvariable;
  	run;

	proc gchart data=bootEstimates; 
    vbar Intercept;
  	run;
	

%mend;
%regBoot(NumberOfLoops = 1000, DataSet = SAS_5763.regData, XVariable = x, YVariable = y);








