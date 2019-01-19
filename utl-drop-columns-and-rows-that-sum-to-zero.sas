Drop columns and rows that sum to zero ;

  https://www.mini.pw.edu.pl/~bjablons/SASpublic/bart_array_v3.sas

  Two Solutions

    1. Elegant one liner in R
       have[rowSums(have) != 0, colSums(have) != 0];

    2. SAS datastep
       Solution uses the array macro by
       Bartosz Jablonski
       yabwon@gmail.com
       https://tinyurl.com/ybqc6gh9
       https://www.mini.pw.edu.pl/~bjablons/SASpublic/bart_array_v3.sas

github
https://tinyurl.com/ycxly2l8
https://github.com/rogerjdeangelis/utl-drop-columns-and-rows-that-sum-to-zero

Stackoverflow
https://tinyurl.com/yaxl97uk
https://stackoverflow.com/questions/54224424/how-to-subset-a-matrix-retaining-colums-and-rows-that-sum-more-than-0

Avenger012
https://stackoverflow.com/users/10023960/avenger012

INPUT
=====

options validvarname=upcase;
libname sd1 "d:/sd1";
data sd1.have;
  array m(5) ;
  input m(*) ;
cards4;
0 1 0 2 3
0 0 0 0 1
0 0 0 0 0
1 0 0 2 0
;;;;
run;quit;

/*
                                |
                                |
 SD1.HAVE total obs=4           |
                                |
   M1    M2    M3    M4    M5   |   M3
                                |
    0     1     0     2     3   |    0
    0     0     0     0     1   |    0

    0     0     0     0     0   |    0  delete this row sum=0

    1     0     0     2     0   |    0
                                   ===
                                     0  Sum do drop M3
*/


EXAMPLE OUTPUT
--------------

WORK.WANT total obs=3

  M1    M2    M4    M5

   0     1     2     3
   0     0     0     1
   1     0     2     0


PROCESS
=======

1. Elegant one liner in R
   have[rowSums(have) != 0, colSums(have) != 0];
   --------------------------------------------

   %utl_submit_r64('
     library(haven);
     library(SASxport);
     have<-as.matrix(read_sas("d:/sd1/have.sas7bdat"));
     want<-as.data.frame(have[rowSums(have) != 0, colSums(have) != 0]);
     write.xport(want,file="d:/xpt/want.xpt");
   ');

   libname xpt xport "d:/xpt/want.xpt";
   data want;
     set xpt.want;
   run;quit;
   libname xpt clear;



2. SAS datastep

   data want;

     if _n_=0 then do; %let rc=%sysfunc(dosubl('
        ods output summary=havSum(where=(sum=0));
        proc means data=sd1.have missing stackodsoutput sum;
        var m1-m5;
        run;quit;
        %barray(ds=havSum, vars=variable);
       '));
     end;

     set sd1.have(drop = %do_over(variable,phrase=?) );
     if sum(of m:)=0 then delete;

   run;quit;

OUTPUT
------
see above
