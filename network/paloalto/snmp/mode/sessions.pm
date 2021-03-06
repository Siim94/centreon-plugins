################################################################################
# Copyright 2005-2014 MERETHIS
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

package network::paloalto::snmp::mode::sessions;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::values;

my $maps_counters = {
    '001_active'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'panSessionActive' }, { name => 'panSessionMax' },
                                      ],
                        output_template => 'Active : %.2f %%', threshold_use => 'active_prct', output_use => 'active_prct',
                        closure_custom_calc => \&custom_active_calc,
                        perfdatas => [
                            { label => 'active', value => 'panSessionActive_absolute', template => '%s',
                              min => 0, max => 'panSessionMax_absolute' },
                        ],
                    }
               },
    '002_active-ssl-proxy'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'panSessionSslProxyUtilization' },
                                      ],
                        output_template => 'Active SSL Proxy : %.2f %%',
                        perfdatas => [
                            { label => 'active_ssl_proxy', value => 'panSessionSslProxyUtilization_absolute', template => '%.2f', unit => '%',
                              min => 0, max => 100 },
                        ],
                    }
               },
    '003_active-tcp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'panSessionActiveTcp' },
                                      ],
                        output_template => 'Active TCP : %s',
                        perfdatas => [
                            { label => 'active_tcp', value => 'panSessionActiveTcp_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '004_active-udp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'panSessionActiveUdp' },
                                      ],
                        output_template => 'Active UDP : %s',
                        perfdatas => [
                            { label => 'active_udp', value => 'panSessionActiveUdp_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
    '005_active-icmp'   => { class => 'centreon::plugins::values', obj => undef,
                 set => {
                        key_values => [
                                        { name => 'panSessionActiveICMP' },
                                      ],
                        output_template => 'Active ICMP : %s',
                        perfdatas => [
                            { label => 'active_icmp', value => 'panSessionActiveICMP_absolute', template => '%s', min => 0 },
                        ],
                    }
               },
};

sub custom_active_calc {
    my ($self, %options) = @_;

    $self->{result_values}->{panSessionActive_absolute} = $options{new_datas}->{$self->{instance} . '_panSessionActive'};
    $self->{result_values}->{panSessionMax_absolute} = $options{new_datas}->{$self->{instance} . '_panSessionMax'};
    $self->{result_values}->{active_prct} = 0;
    if ($self->{result_values}->{panSessionMax_absolute} != 0) {
        $self->{result_values}->{active_prct} = $self->{result_values}->{panSessionActive_absolute} * 100 / $self->{result_values}->{panSessionMax_absolute};
    }
    return 0;
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                });                         

    foreach (keys %{$maps_counters}) {
        my ($id, $name) = split /_/;
        if (!defined($maps_counters->{$_}->{threshold}) || $maps_counters->{$_}->{threshold} != 0) {
            $options{options}->add_options(arguments => {
                                                        'warning-' . $name . ':s'    => { name => 'warning-' . $name },
                                                        'critical-' . $name . ':s'    => { name => 'critical-' . $name },
                                           });
        }
        my $class = $maps_counters->{$_}->{class};
        $maps_counters->{$_}->{obj} = $class->new(output => $self->{output}, perfdata => $self->{perfdata},
                                                  label => $name);
        $maps_counters->{$_}->{obj}->set(%{$maps_counters->{$_}->{set}});
    }
    
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);
    
    foreach (keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->init(option_results => $self->{option_results});
    }    
}

sub run {
    my ($self, %options) = @_;
    # $options{snmp} = snmp object
    $self->{snmp} = $options{snmp};
    
    $self->manage_selection();
    
    my ($short_msg, $short_msg_append, $long_msg, $long_msg_append) = ('', '', '', '');
    my @exits;
    foreach (sort keys %{$maps_counters}) {
        $maps_counters->{$_}->{obj}->set(instance => 'global');
    
        my ($value_check) = $maps_counters->{$_}->{obj}->execute(values => $self->{global});

        if ($value_check != 0) {
            $long_msg .= $long_msg_append . $maps_counters->{$_}->{obj}->output_error();
            $long_msg_append = ', ';
            next;
        }
        my $exit2 = $maps_counters->{$_}->{obj}->threshold_check();
        push @exits, $exit2;

        my $output = $maps_counters->{$_}->{obj}->output();
        $long_msg .= $long_msg_append . $output;
        $long_msg_append = ', ';
        
        if (!$self->{output}->is_status(litteral => 1, value => $exit2, compare => 'ok')) {
            $short_msg .= $short_msg_append . $output;
            $short_msg_append = ', ';
        }
        
        $maps_counters->{$_}->{obj}->perfdata();
    }

    my $exit = $self->{output}->get_most_critical(status => [ @exits ]);
    if (!$self->{output}->is_status(litteral => 1, value => $exit, compare => 'ok')) {
        $self->{output}->output_add(severity => $exit,
                                    short_msg => "Sessions $short_msg"
                                    );
    } else {
        $self->{output}->output_add(short_msg => "Sessions $long_msg");
    }
     
    $self->{output}->display();
    $self->{output}->exit();
}

my $mapping = {
    panSessionMax                   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.2' },
    panSessionActive                => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.3' },
    panSessionActiveTcp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.4' },
    panSessionActiveUdp             => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.5' },
    panSessionActiveICMP            => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.6' },
    #panSessionActiveSslProxy        => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.7' }, Cannot get the max if 0...
    panSessionSslProxyUtilization   => { oid => '.1.3.6.1.4.1.25461.2.1.2.3.8' },
};

sub manage_selection {
    my ($self, %options) = @_;

    my $oid_panSession = '.1.3.6.1.4.1.25461.2.1.2.3';
    $self->{results} = $self->{snmp}->get_table(oid => $oid_panSession,
                                                nothing_quit => 1);
    $self->{global} = $self->{snmp}->map_instance(mapping => $mapping, results => $self->{results}, instance => '0');
}

1;

__END__

=head1 MODE

Check sessions.

=over 8

=item B<--warning-*>

Threshold warning.
Can be: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).

=item B<--critical-*>

Threshold critical.
Can be: 'active' (%), 'active-tcp', 'active-udp', 'active-icmp', 'active-ssl-proxy' (%).

=back

=cut
