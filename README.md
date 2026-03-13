# PolyspaceReportAutoDiag

A lightweight diagnostic tool written in Perl and used to collect the information required to debug issues with the Polyspace Report Generator.

This utility gathers essential runtime and configuration details on the report generator including its main component called the connector. It then produces three text files that must be sent to the support team for analysis.

More information on troubleshooting the connector can also be found here: https://www.mathworks.com/help/releases/R2024b/polyspace_access/ug/troubleshoot-issues-with-the-polyspace-connector.html

# Usage

The Perl script takes two arguments:

`<path_to_product>`: Path to the installed product whose report generator needs debugging.

`<path_to_results_folder>`: Folder where the tool will write the generated diagnostic files. Must be writable.

Under Linux the command to launch is then:

 `perl ReportAutoDiag.pl <path_to_product> <path_to_results_folder>`

Under Windows, you can use the Perl installation available with the installation of Polyspace. Indeed a Perl executable is available in `<PATH_TO_PRODUCT>\sys\perl\win32\bin\perl.exe`.
Here is a .bat script that will launch perl with the Perl script in argument:

```bat
@echo off

:: Change the following path to your Polyspace installation
set PATH_TO_PRODUCT=C:\Program Files\Polyspace\R2026a

:: Change the following path to your Polyspace installation
set PATH_TO_RESULTS=C:\Workspace\Polyspace\MyProject\BF_Result
	
"%PATH_TO_PRODUCT%"\sys\perl\win32\bin\perl.exe ReportAutoDiag.pl --debug "%PATH_TO_PRODUCT%" "%PATH_TO_RESULTS%"
```

# Output
After execution, the tool creates three text files inside the execution folder:

* `connector_log.txt`: The log of a component called connector.

* `route_results.json`: A Json file created via a route to get information on the results folder (2nd argument of the tool)

* `report_debug_log.txt`: Contains collected diagnostic output, extracted logs, and useful debugging traces.

These files are required for the support team to properly reproduce and analyze the issue.

# Sending the Files to Support

Please attach the 3 generated text files to your support ticket.

The support team relies on these files to efficiently troubleshoot your report generator issue.

# Notes

Make sure the product and results folder paths are correct and accessible.
Run the tool with appropriate permissions if the product folder requires elevated rights.
