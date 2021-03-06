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

package database::informix::mode::archivelevel0;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::misc;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                { 
                                  "warning:s"               => { name => 'warning', },
                                  "critical:s"              => { name => 'critical', },
                                  "name:s"                  => { name => 'name', },
                                  "regexp"                  => { name => 'use_regexp' },
                                });

    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
       $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
       $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
       $self->{output}->option_exit();
    }
}

sub run {
    my ($self, %options) = @_;
    # $options{sql} = sqlmode object
    $self->{sql} = $options{sql};

    $self->{sql}->connect();

    my $query = q{
SELECT name, level0 FROM sysdbstab
};
    
    $self->{sql}->query(query => $query);

    if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp})) {
        $self->{output}->output_add(severity => 'OK',
                                    short_msg => 'All archive level0 backups are ok');
    }
    
    my $count = 0;
    while ((my $row = $self->{sql}->fetchrow_hashref())) {
        my $name = centreon::plugins::misc::trim($row->{name});
        next if (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}) && $name ne $self->{option_results}->{name});
        next if (defined($self->{option_results}->{name}) && defined($self->{option_results}->{use_regexp}) && $name !~ /$self->{option_results}->{name}/);
        
        $count++;
        if ($row->{level0} == 0) {
            $self->{output}->output_add(severity => 'UNKNOWN',
                                        short_msg => sprintf("Dbspace '%s' archive level0 had never been executed", $name));
            next;
        }
        
        my $diff_time = time() - $row->{level0};
        $self->{output}->output_add(long_msg => sprintf("Dbspace '%s' archive level0 last execution date %s",
                                                         $name, localtime($row->{level0})));
        my $exit_code = $self->{perfdata}->threshold_check(value => $diff_time, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        
        if (!$self->{output}->is_status(value => $exit_code, compare => 'ok', litteral => 1) || 
            (defined($self->{option_results}->{name}) && !defined($self->{option_results}->{use_regexp}))) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("Dbspace '%s' archive level0 last execution date %s",
                                                             $name, localtime($row->{level0})));
        }
        
        my $extra_label = '';
        $extra_label = '_' . $name if (!defined($self->{option_results}->{name}) || defined($self->{option_results}->{use_regexp}));
        $self->{output}->perfdata_add(label => 'seconds' . $extra_label,
                                      value => $diff_time,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      min => 0);
    }

    if ($count == 0) {
        $self->{output}->output_add(severity => 'UNKNOWN',
                                    short_msg => "Cannot find a dbspace (maybe the filter).");
    }
    
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check archive level0 backup last execution.

=over 8

=item B<--warning>

Threshold warning in seconds since last execution.

=item B<--critical>

Threshold critical in seconds since last execution.

=item B<--name>

Set the dbspace (empty means 'check all dbspaces').

=item B<--regexp>

Allows to use regexp to filter dbspaces (with option --name).

=back

=cut
