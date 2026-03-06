@echo off

:: Change the following path to your Polyspace installation
set PATH_TO_PRODUCT=L:\Program Files\Polyspace\R2026a

:: Change the following path to your Polyspace installation
set PATH_TO_RESULTS=L:\Program Files\Polyspace\R2026a\polyspace\examples\cxx\Bug_Finder_Example\Module_1\BF_Result
	
	
:::::
"%PATH_TO_PRODUCT%"\sys\perl\win32\bin\perl.exe  ReportAutoDiag.pl --debug "%PATH_TO_PRODUCT%" "%PATH_TO_RESULTS%"
