Drop columns and rows that sum to zero. Drop columns and rows that sum to zero ;

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

    3. Single datastep HASH (original example of creating the PDV at runtime)
       Paul Dorfman <sashole@BELLSOUTH.NET>
       Very interesting 'h.definedata (vname(m))' define
       the PDV ar runtime. Not only can a HASH create
       dynamic table names at run time but it also can define
       a dynamic PDV?

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

3. Single datastep HASH (original example of creating the PDV at runtime)

   Recent single datastep solution by Paul Dorfman.
   Paul Dorfman <sashole@BELLSOUTH.NET>

    Very interesting 'h.definedata (vname(m))' define
   the PDV ar runtime. Not only can a HASH create
   dynamic table names at run time but it also can define
   a dynamic PDV?

    Only disadvangage is loading the dataset into arrays.
   But with inexpensize ram this is less of a drawback, of course
   unless yo are using EG on a server?

    However, returning to the academic exercise, an interesting
   question is whether it can be done without crossing step boundaries
   even once. EXECUTE and DOSUBL only appear to attain that since in
   reality, EXECUTE just generates another step, and
   DOSUBL (as Rick Langston has once admitted), is nothing but %INCLUDE behind-the-scenes.
   It seems as though the only way to have a truly closed
   one-step solution is to use the hash object because its variables can be defined at run time:


data have ;
  input m1-m7 ;
cards ;
0 1 0 2 3 0 1
0 0 0 0 0 0 0
0 0 0 0 1 0 2
0 0 0 0 0 0 0
1 0 0 2 0 0 4
;
run ;


data _null_ ;
  do until (z1) ;
    set have end = z1 ;
    array m m: ;
    array s [7] _temporary_ ;
    do over m ;
      if m then s [_i_] = 1 ;
    end ;
  end ;
  dcl hash h (multidata:"Y") ;
  h.definekey ("_n_") ;
  do over m ;
    if s [_i_] then h.definedata (vname(m)) ;
  end ;
  h.definedone() ;
  do until (z2) ;
    set have end = z2 ;
    if sum (of m:) then h.add() ;
  end ;
  h.output (dataset: "want") ;
  stop ;
run ;


OUTPUT
------
see above


