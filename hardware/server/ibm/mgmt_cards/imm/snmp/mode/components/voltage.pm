################################################################################
# Copyright 2005-2013 MERETHIS
# Centreon is developped by : Julien Mathis and Romain Le Merlus under
# GPL Licence 2.0.
# 
# This program is free software; you can redistribute it and/or modify it under 
# the terms of the GNU General Public License as published by the Free Software 
# Foundation ; either version 2 of the License.
# 
# This program is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A 
# PARTICULAR PURPOSE. See the GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along with 
# this program; if not, see <http://www.gnu.org/licenses>.
# 
# Linking this program statically or dynamically with other modules is making a 
# combined work based on this program. Thus, the terms and conditions of the GNU 
# General Public License cover the whole combination.
# 
# As a special exception, the copyright holders of this program give MERETHIS 
# permission to link this program with independent modules to produce an executable, 
# regardless of the license terms of these independent modules, and to copy and 
# distribute the resulting executable under terms of MERETHIS choice, provided that 
# MERETHIS also meet, for each linked independent module, the terms  and conditions 
# of the license of that module. An independent module is a module which is not 
# derived from this program. If you modify this program, you may extend this 
# exception to your version of the program, but you are not obliged to do so. If you
# do not wish to do so, delete this exception statement from your version.
# 
# For more information : contact@centreon.com
# Authors : Quentin Garnier <qgarnier@merethis.com>
#
####################################################################################

package hardware::server::ibm::mgmt_cards::imm::snmp::mode::components::voltage;

use strict;
use warnings;
use centreon::plugins::misc;

sub check {
    my ($self) = @_;

    $self->{components}->{voltages} = {name => 'voltages', total => 0};
    $self->{output}->output_add(long_msg => "Checking voltages");
    return if ($self->check_exclude('voltages'));
    
    my $oid_voltEntry = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1';
    my $oid_voltDescr = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.2';
    my $oid_voltReading = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.3';
    my $oid_voltCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.6';
    my $oid_voltNonCritLimitHigh = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.7';
    my $oid_voltCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.9';
    my $oid_voltNonCritLimitLow = '.1.3.6.1.4.1.2.3.51.3.1.2.2.1.10';
    
    my $result = $self->{snmp}->get_table(oid => $oid_voltEntry);
    return if (scalar(keys %$result) <= 0);

    foreach my $key ($self->{snmp}->oid_lex_sort(keys %$result)) {
        next if ($key !~ /^$oid_voltDescr\.(\d+)$/);
        my $instance = $1;
    
        my $volt_descr = centreon::plugins::misc::trim($result->{$oid_voltDescr . '.' . $instance});
        my $volt_value = $result->{$oid_voltReading . '.' . $instance};
        my $volt_crit_high = $result->{$oid_voltCritLimitHigh . '.' . $instance};
        my $volt_warn_high = $result->{$oid_voltNonCritLimitHigh . '.' . $instance};
        my $volt_crit_low = $result->{$oid_voltCritLimitLow . '.' . $instance};
        my $volt_warn_low = $result->{$oid_voltNonCritLimitLow . '.' . $instance};
        
        my $warn_threshold = '';
        $warn_threshold = $volt_warn_low . ':' if ($volt_warn_low != 0);
        $warn_threshold .= $volt_warn_high if ($volt_warn_high != 0);
        my $crit_threshold = '';
        $crit_threshold = $volt_crit_low . ':' if ($volt_crit_low != 0);
        $crit_threshold .= $volt_crit_high if ($volt_crit_high != 0);
        
        $self->{perfdata}->threshold_validate(label => 'warning_' . $instance, value => $warn_threshold);
        $self->{perfdata}->threshold_validate(label => 'critical_' . $instance, value => $crit_threshold);
        
        my $exit = $self->{perfdata}->threshold_check(value => $volt_value, threshold => [ { label => 'critical_' . $instance, 'exit_litteral' => 'critical' }, { label => 'warning_' . $instance, exit_litteral => 'warning' } ]);
        
        $self->{components}->{temperatures}->{total}++;
        $self->{output}->output_add(long_msg => sprintf("Voltage '%s' value is %s.", 
                                    $volt_descr, $volt_value));
        if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit,
                                        short_msg => sprintf("Voltage '%s' value is %s", $volt_descr, $volt_value));
        }
        
        $self->{output}->perfdata_add(label => 'volt_' . $volt_descr,
                                      value => $volt_value,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning_' . $instance),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical_' . $instance),
                                      );
    }
}

1;