#! /usr/bin/perl -w
###################################################################
# Oreon is developped with GPL Licence 2.0 
#
# GPL License: http://www.gnu.org/licenses/gpl.txt
#
# Developped by : Julien Mathis - Romain Le Merlus 
#                 Christophe Coraboeuf
#
###################################################################
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
#    For information : contact@merethis.com
####################################################################
#
# Script init
#

use strict;
use Net::SNMP qw(:snmp oid_lex_sort);
use FindBin;
use lib "$FindBin::Bin";
use lib "/usr/local/nagios/libexec/";
use utils qw($TIMEOUT %ERRORS &print_revision &support);
if (eval "require oreon" ) {
    use oreon qw(get_parameters);
    use vars qw($VERSION %oreon);
    %oreon=get_parameters();
} else {
	print "Unable to load oreon perl module\n";
    exit $ERRORS{'UNKNOWN'};
}

use vars qw($PROGNAME);
use Getopt::Long;
use vars qw($opt_V  $opt_h $opt_a $opt_v $opt_C $opt_p $opt_H $opt_n $opt_k $opt_u $opt_x $result @result $opt_c $opt_w $opt_f %process_list %STATUS);

# Plugin var init

my($proc, $proc_run);

$PROGNAME = "check_graph_process";
sub print_help ();
sub print_usage ();
%STATUS=(1=>'running',2=>'runnable',3=>'notRunnable',4=>'invalid');

Getopt::Long::Configure('bundling');
GetOptions
    ("h"   => \$opt_h, "help"         => \$opt_h,
     "u=s"   => \$opt_u, "username=s" => \$opt_u,
     "x=s"   => \$opt_x, "password=s" => \$opt_x,
     "k=s"   => \$opt_k, "key=s"      => \$opt_k,
     "V"   => \$opt_V, "version"      => \$opt_V,
     "n"   => \$opt_n, "number"       => \$opt_n,
     "v=s" => \$opt_v, "snmp=s"       => \$opt_v,
     "f" => \$opt_f, "full_pathname"       => \$opt_f,
     "a=s" => \$opt_a, "arguments=s"       => \$opt_a,
     "C=s" => \$opt_C, "community=s"  => \$opt_C,
     "p=s" => \$opt_p, "process=s"    => \$opt_p,
     "H=s" => \$opt_H, "hostname=s"   => \$opt_H);

if ($opt_V) {
    print_revision($PROGNAME,'$Revision: 1.2 $');
 exit $ERRORS{'OK'};
}

if ($opt_h) {
  print_help();
 exit $ERRORS{'OK'};
}

if (!$opt_H) {
print_usage();
exit $ERRORS{'OK'};
}
my $snmp = "1";
if ($opt_v && $opt_v =~ /^[0-9]$/) {
$snmp = $opt_v;
}

if ($snmp eq "3") {
if (!$opt_u) {
print "Option -u (--username) is required for snmpV3\n";
exit $ERRORS{'OK'};
}
if (!$opt_x && !$opt_k) {
print "Option -k (--key) or -x (--password) is required for snmpV3\n";
exit $ERRORS{'OK'};
}elsif ($opt_x && $opt_k) {
print "Only option -k (--key) or -x (--password) is needed for snmpV3\n";
exit $ERRORS{'OK'};
}
}

if (!$opt_C) {
$opt_C = "public";
}

my $process;
if(!$opt_p) {
print_usage();
exit $ERRORS{'OK'};
}elsif ($opt_p !~ /([-.A-Za-z0-9]+)/){
print_usage();
exit $ERRORS{'OK'};
}
$process = $opt_p;

my $name = $0;
$name =~ s/\.pl.*//g;

# Plugin snmp requests
my $OID_SW_RunName = $oreon{MIB2}{SW_RUNNAME};
if ($opt_f) {
	$OID_SW_RunName = $oreon{MIB2}{SW_RUNFULLPATHNAME};
}
my $OID_SW_Runargs = $oreon{MIB2}{SW_RUNARGS};
my $OID_SW_RunIndex =$oreon{MIB2}{SW_RUNINDEX};
my $OID_SW_RunStatus =$oreon{MIB2}{SW_RUNSTATUS};

my ($session, $error);
if ($snmp eq "1" || $snmp eq "2") {
($session, $error) = Net::SNMP->session(-hostname => $opt_H, -community => $opt_C, -version => $snmp);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}elsif ($opt_k) {
    ($session, $error) = Net::SNMP->session(-hostname => $opt_H, -version => $snmp, -username => $opt_u, -authkey => $opt_k);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}elsif ($opt_x) {
    ($session, $error) = Net::SNMP->session(-hostname => $opt_H, -version => $snmp,  -username => $opt_u, -authpassword => $opt_x);
if (!defined($session)) {
    print("UNKNOWN: SNMP Session : $error\n");
    exit $ERRORS{'UNKNOWN'};
}
}

$result = $session->get_table(Baseoid => $OID_SW_RunName);
if (!defined($result)) {
    printf("UNKNOWN: %s.\n", $session->error);
    $session->close;
    exit $ERRORS{'UNKNOWN'};
}

$proc = 0;
foreach my $key (oid_lex_sort(keys %$result)) {
    my @oid_list = split (/\./,$key);
    my $args_index = $oid_list[scalar(@oid_list) - 1];
    if (defined($opt_p) && $opt_p ne ""){
	if ($$result{$key} eq $opt_p){
		my $result2 = $session->get_request(-varbindlist => [$OID_SW_Runargs . "." . $args_index]);
		if (!defined($result2)) {
         	   printf("UNKNOWN: %s.\n", $session->error);
        	    $session->close;
        	    exit $ERRORS{'UNKNOWN'};
        	}
		if ($opt_a && $result2->{$OID_SW_Runargs . "." . $args_index} =~ /$opt_a/) {
			$proc++	;		
    			$process_list{$result->{$key}} =  pop (@oid_list) ;
		}elsif (!$opt_a) { 
    			$process_list{$result->{$key}} =  pop (@oid_list) ;
			$proc++;
		}
	}
    } else {
	$proc++;
    }
}

if (!($opt_n))
{
    if ($process_list{$process}) {
        $result = $session->get_request(-varbindlist => [$OID_SW_RunStatus . "." . $process_list{$process}]);
        if (!defined($result)) {
            printf("UNKNOWN: %s.\n", $session->error);
            $session->close;
            exit $ERRORS{'UNKNOWN'};
        }
	$proc_run =  $result->{$OID_SW_RunStatus . "." . $process_list{$process} };
    }
}
if ($opt_n){
    if ($proc > 0) {
	print "Processes OK - Number of current processes: $proc|nbproc=$proc\n";
    	exit $ERRORS{'OK'};
	}else {
      	 print "Process CRITICAL - $process not in 'running' state\n";
		exit $ERRORS{'CRITICAL'};
	}
} else {
    if ($proc_run){
        print "Process OK - $process: $STATUS{$proc_run}|procstatus=$proc_run\n";
        exit $ERRORS{'OK'};
    } else {
        print "Process CRITICAL - $process not in 'running' state\n";
        exit $ERRORS{'CRITICAL'};
    }
}
# Plugin return code
if ( $opt_n) {
	if ($proc) {
	    print "Processes OK - Number of current processes: $proc|nbproc=$proc\n";	
	    exit $ERRORS{'OK'};

	}else {
       	    print "Process CRITICAL - $process not in 'running' state\n";
	    exit $ERRORS{'CRITICAL'};			
	}
}else {
    if ($proc_run){
	    print "Process OK - $process: $STATUS{$proc_run}|procstatus=$proc_run\n";
	    exit $ERRORS{'OK'};
    } else {
        print "Process CRITICAL - $process not in 'running' state\n";
        exit $ERRORS{'CRITICAL'};
    }
}

sub print_usage () {
    print "Usage:\n";
    print "$PROGNAME\n";
    print "   -H (--hostname)   Hostname to query - (required)\n";
    print "   -C (--community)  SNMP read community (defaults to public,\n";
    print "                     used with SNMP v1 and v2c\n";
    print "   -v (--snmp_version)  1 for SNMP v1 (default)\n";
    print "                        2 for SNMP v2c\n";
    print "   -a (--arguments)  arguments of process you want to check\n";
    print "   -f (--full_pathname) process with its full path\n";
    print "   -n (--number)     Return the number of current running processes. \n";
    print "   -p (--process)    Set the process name ex: by default smbd\n";
    print "   -V (--version)    Plugin version\n";
    print "   -h (--help)       usage help\n";
}

sub print_help () {
    print "######################################################\n";
    print "#      Copyright (c) 2004-2007 Oreon-project         #\n";
	print "#      Bugs to http://www.oreon-project.org/         #\n";
	print "######################################################\n";
    print_usage();
    print "\n";
}
