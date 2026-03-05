#!/usr/bin/perl

use File::Temp qw(tempdir);
use JSON::PP qw(decode_json);
use Getopt::Long qw(GetOptions);
use strict;
use warnings;
use feature 'say';

binmode STDOUT, ':encoding(UTF-8)';  # in case of Unicode


###########################
# Variables and constants #
###########################

my $VER = "1.0";
my $os = $^O;
my $is_windows = 0;
my $log_path = "report_debug_log.txt";
my $LOG;
my $path_connector;
my $path_report;
my $path_bf;
my $path_bf_example;
my $path_bf_template;
my $command;
my $temp_dir;
my $rc;
my $full_version; # R2025a Update 1
my $version;  # R2025a
my $out;
my $debug  = 0;        # 0 = off
my $help = 0;
my $path_prod;
my $NUL;
my $json;

#############
# Functions #
#############


sub usage {
    my ($exit) = @_;
    print <<"USAGE";
Usage: $0 [options]

Options:
  --debug         Enable debug output
  --help, -h      Show this help

Examples:
  $0 --debug

USAGE
    exit($exit // 0);
}


GetOptions(
    'debug'  => \$debug,
    'help|h'   => \$help,
) or usage(2) ;


sub log_msg {
    my ($msg) = @_;
    chomp $msg;
    my $line = "$msg\n";
    print $line;        # STDOUT
    print {$LOG} $line; # File
    return;
}

sub DEBUG {
    if ($debug) {
      log_msg(" [DEBUG] @_");
    }
    return;
}

# Compare release numbers
# Return -1, 0, 1 like <=> does
sub relcmp {
    my ($lhs, $rhs) = @_;
    my @L = parse_release($lhs);
    my @R = parse_release($rhs);

    # Compare year, then half (a<b), then update
    return ($L[0] <=> $R[0]) || ($L[1] <=> $R[1]) || ($L[2] <=> $R[2]);
}



sub parse_release {
    my ($s) = @_;
    # Capture: R, 4 digits, a/b, optional "Update N"
    my ($year, $half, $update) = $s =~ /
        R (\d{4})           # year
        ([ab])              # half (a or b)
        (?: \s+ Update \s+ (\d+) )?  # optional "Update N"
    /ix
        or die "Not a valid release string: '$s'";

    my %half_idx = ( a => 0, b => 1 );
    return ($year + 0, $half_idx{lc $half}, ($update // 0) + 0);
}


# Extract the JSON block (object or array) as a single string.
# Returns undef on failure (no JSON found or unbalanced).
sub extract_json_block {
    my ($str) = @_;

    # Find the first opening brace or bracket
    my $obj_start = index($str, '{');
    my $arr_start = index($str, '[');

    my $start;
    my $open_char;
    if ($obj_start == -1 && $arr_start == -1) {
        return undef;  # No JSON opener found
    } elsif ($obj_start == -1) {
        $start     = $arr_start;
        $open_char = '[';
    } elsif ($arr_start == -1) {
        $start     = $obj_start;
        $open_char = '{';
    } else {
        # Pick whichever appears first
        if ($obj_start < $arr_start) {
            $start     = $obj_start;
            $open_char = '{';
        } else {
            $start     = $arr_start;
            $open_char = '[';
        }
    }

    my $close_char = ($open_char eq '{') ? '}' : ']';

    # Scan forward balancing braces/brackets, skipping strings
    my $level = 0;
    my $in_string = 0;   # inside JSON string (")
    my $escaped   = 0;   # previous char was backslash
    my $end = -1;

    for (my $i = $start; $i < length($str); $i++) {
        my $ch = substr($str, $i, 1);

        if ($in_string) {
            if ($escaped) {
                # Escaped char inside string; consume and reset escaped flag
                $escaped = 0;
            } else {
                if ($ch eq '\\') {
                    $escaped = 1;
                } elsif ($ch eq '"') {
                    $in_string = 0;
                }
            }
            next;
        }

        # Not inside a string
        if ($ch eq '"') {
            $in_string = 1;
            next;
        }

        if ($ch eq $open_char) {
            $level++;
        } elsif ($ch eq $close_char) {
            $level--;
            if ($level == 0) {
                $end = $i;
                last;
            }
        } elsif ($ch eq '{' || $ch eq '[') {
            # Nested structure of either type increases level
            $level++;
        } elsif ($ch eq '}' || $ch eq ']') {
            # Closing of either type decreases level
            $level--;
            if ($level == 0) {
                $end = $i;
                last;
            }
        }
    }

    return undef if $end == -1;  # Unbalanced or no closing found
    return substr($str, $start, $end - $start + 1);
}

# Convenience: return the JSON block as an arrayref of lines
sub extract_json_lines {
    my ($str) = @_;
    my $json = extract_json_block($str) or return undef;
    my @lines = split /\R/, $json;  # split on any newline sequence
    return \@lines;
}



#############
#   Inits   #
#############

$temp_dir = tempdir( CLEANUP => 1 );  # auto‑delete at end of scope
$is_windows = ($os =~ /MSWin32/i);
$path_prod = $ARGV[0];


############
#   Main   #
############

usage(0) if $help;   # will exit systematically

open $LOG, '>', $log_path or die "Can't open $log_path: $!";

DEBUG("Debug enabled");

if ( $is_windows) {
	$NUL = "NUL";
	$path_connector = "\"$path_prod\\polyspace\\bin\\win64\\polyspace-connector.exe\"";
	$path_report = "\"$path_prod\\polyspace\\bin\\polyspace-report-generator.exe\"";
	$path_bf = "\"$path_prod\\polyspace\\bin\\polyspace-bug-finder.exe\"";
	$path_bf_example = "\"$path_prod\\polyspace\\examples\\cxx\\Bug_Finder_Example\\Module_1\\BF_Result\"";
	$path_bf_example = "L:/BF_Result";
	#$path_bf_example_no_quote = "$path_prod\\polyspace\\examples\\cxx\\Bug_Finder_Example\\Module_1\\BF_Result";
	$path_bf_template =  "\"$path_prod\\toolbox\\polyspace\\psrptgen\\templates\\bug_finder\\BugFinder.rpt\"";
} else {
	$NUL = "/dev/null";
	$path_connector = "$path_prod/polyspace/bin/glnxa64/polyspace-connector";
	$path_report =  "$path_prod/polyspace/bin/polyspace-report-generator";
	$path_bf = "$path_prod/polyspace/bin/polyspace-bug-finder";
	$path_bf_example = "$path_prod/polyspace/examples/cxx/Bug_Finder_Example/Module_1/BF_Result";
	$path_bf_template =  "$path_prod/toolbox/polyspace/psrptgen/templates/bug_finder/BugFinder.rpt";
}

#  path must exist AND be a directory
if ( ! -e $path_prod ) {
    die "Error: The path '$path_prod' does not exist.\n";
}

if ( ! -d $path_prod ) {
    die "Error: The path '$path_prod' exists but is NOT a directory.\n";
}

print <<END;

=======================
       ReportDiag
 v$VER
 
 (C) MathWorks, 2026
======================= 

This utility assists in identifying and troubleshooting problems encountered while using the Polyspace Report Generator.
The tool will generate a log file named $log_path to send to the support.

END

# 1. Get information
# - version including update
# - Product
# - Size of the results

log_msg("= 1. Information =");

$command = "$path_bf -version";
$out = qx{$command};
($full_version) = $out =~ /\(([^)]*)\)/;
($version) = $out =~ /(R\d{4}[ab])/;

log_msg(" Product version (including update): $full_version");

# my $proxy = $ENV{'HTTP_PROXY'} // $ENV{'http_proxy'};
my $proxy = $ENV{'HTTP_PROXY'};

if (defined $proxy) {
    print "Proxy = $proxy\n";
else {
    print "HTTP_PROXY is not set.\n";
}


if (0) {
# 2. Test the report on a simple example with -debug
log_msg("\n= 2. Testing the Report Generator =");
log_msg("Using 'Bug Finder Example' with the Bug Finder template");
$command = "$path_report -results-dir $path_bf_example -output-name $temp_dir -template $path_bf_template -format HTML";
DEBUG("The command is: $command\n");
print "Please wait\n";

$rc = system("$command > $NUL 2>&1");
DEBUG("Command is done, result code: $rc\n");
if ($rc == 0) {
	log_msg("Report generation was successful");
} else {
	log_msg("Report generation failed");
}

}
# Test of the connector
log_msg("\n= 3. Testing the connector =");

$command = "$path_connector -server.port 9099 --profile matlab -debug";

# Launch the command in background
if ($is_windows) {
	$command = qq{start "" /B cmd /C $command};
	# $command = qq{$command ^>> $log_path 2^>^&1};
 } else {
	 $command = qq{$command &};
 }
log_msg("Using the command: $command");
system("$command 2>&1");
print "toto\n";

#wait 
sleep 5;

# Terminate the connector
$command = "curl http://localhost:9099/polyspace/api/$version/connector/shutdown";
log_msg("\nClosing the connector using $command");
if ($is_windows) {
	qx{$command 2^>^&1};
} else {
	qx{$command 2>&1 &};
}

# Get the metadata
log_msg("\n= 4. Getting metadata from the connector =");
log_msg("Using curl on localhost:9099/metadata");

$command = "curl http://localhost:9099/metadata";
DEBUG("Command is $command\n");

$out = qx{$command 2>&1};
$rc = $? >> 8;
DEBUG("output is $out");
$json = extract_json_block($out);
DEBUG("json : $json");

my $data = decode_json($json);
my $status_code    = $data->{status}{statusCode};
my $access_version = $data->{payload}{'Access version'};
my $release        = $data->{payload}{Release};

log_msg("\nstatusCode: $status_code");
log_msg("Access version: $access_version");
log_msg("Release: $release");



log_msg("\nFile $log_path generated, please send it to MathWorks");
close($LOG);
exit;

# if (relcmp($version, 'R2026a') >= 0) {
 
print "bf ex path $path_bf_example\n";
$command = "curl --header \"Content-Type: application/json\" --request POST --data \"{ \\\"resultsFolderURI\\\": \\\"file:/$path_bf_example\\\" }\" http://localhost:9099/polyspace/api/$version/connector/result/summary";
DEBUG("Command is $command");
$out = qx{$command 2>&1};
print "output is $out\n";

#shuting the connector down
$command = "curl http://localhost:9099/polyspace/api/R2026a/connector/shutdown > $NUL 2>&1";
qx{$command};
$rc = $? >> 8;

print "The connector output is:\n";
print "$out\n";
# }

#http://localhost:9099/polyspace/api/R2026a/connector/shutdown

#PATH_TO_PRODUCT


# proxy?

# VPN?


# launch the report with an example to know if the issue is project-specific

  
