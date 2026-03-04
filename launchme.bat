@echo off
:: Change the following path to your Polyspace installation
set PATH_TO_PRODUCT=L:\Program Files\Polyspace\R2026a
																					   
:::::
"%PATH_TO_PRODUCT%"\sys\perl\win32\bin\perl.exe  ReportAutoDiag.pl --debug "%PATH_TO_PRODUCT%"
:: --debug

