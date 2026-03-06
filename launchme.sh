#!/usr/bin/env bash

# Change the following path to your Polyspace installation (Linux path!)
PATH_TO_PRODUCT="/mathworks/UK/devel/jobarchive/BR2025bd/latest_pass/matlab"

# Change the following path to the results folder used to create the report
PATH_TO_RESULTS="/mathworks/UK/devel/jobarchive/BR2025bd/latest_pass/matlab/polyspace/examples/cxx/Bug_Finder_Example/Module_1/BF_Result"

# Launch the Perl script
perl ReportAutoDiag.pl "$PATH_TO_PRODUCT" "$PATH_TO_RESULTS"
