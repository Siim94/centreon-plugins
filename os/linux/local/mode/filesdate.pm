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

package os::linux::local::mode::filesdate;

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
                                  "hostname:s"        => { name => 'hostname' },
                                  "remote"            => { name => 'remote' },
                                  "ssh-option:s@"     => { name => 'ssh_option' },
                                  "ssh-path:s"        => { name => 'ssh_path' },
                                  "ssh-command:s"     => { name => 'ssh_command', default => 'ssh' },
                                  "timeout:s"         => { name => 'timeout', default => 30 },
                                  "sudo"              => { name => 'sudo' },
                                  "command-path:s"    => { name => 'command_path' },
                                  "warning:s"         => { name => 'warning', },
                                  "critical:s"        => { name => 'critical', },
                                  "separate-dirs"     => { name => 'separate_dirs', },
                                  "max-depth:s"       => { name => 'max_depth', },
                                  "exclude-du:s@"     => { name => 'exclude_du', },
                                  "filter-plugin:s"   => { name => 'filter_plugin', },
                                  "files:s"           => { name => 'files', },
                                  "time:s"            => { name => 'time', },
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
    if (!defined($self->{option_results}->{files}) || $self->{option_results}->{files} eq '') {
       $self->{output}->add_option_msg(short_msg => "Need to specify files option.");
       $self->{output}->option_exit();
    }
    
    #### Create command_options
    $self->{option_results}->{command} = 'du';
    $self->{option_results}->{command_options} = '-x --time-style=+%s';
    if (defined($self->{option_results}->{separate_dirs})) {
        $self->{option_results}->{command_options} .= ' --separate-dirs';
    }
    if (defined($self->{option_results}->{max_depth})) {
        $self->{option_results}->{command_options} .= ' --max-depth=' . $self->{option_results}->{max_depth};
    }
    if (defined($self->{option_results}->{time})) {
        $self->{option_results}->{command_options} .= ' --time=' . $self->{option_results}->{time};
    } else {
        $self->{option_results}->{command_options} .= ' --time';
    }
    foreach my $exclude (@{$self->{option_results}->{exclude_du}}) {
        $self->{option_results}->{command_options} .= " --exclude='" . $exclude . "'";
    }
    $self->{option_results}->{command_options} .= ' ' . $self->{option_results}->{files};
    $self->{option_results}->{command_options} .= ' 2>&1';
}

sub run {
    my ($self, %options) = @_;
    my $total_size = 0;
    my $current_time = time();

    my $stdout = centreon::plugins::misc::execute(output => $self->{output},
                                                  options => $self->{option_results},
                                                  sudo => $self->{option_results}->{sudo},
                                                  command => $self->{option_results}->{command},
                                                  command_path => $self->{option_results}->{command_path},
                                                  command_options => $self->{option_results}->{command_options});
    
    $self->{output}->output_add(severity => 'OK', 
                                short_msg => "All file/directory times are ok.");
    foreach (split(/\n/, $stdout)) {
        next if (!/(\d+)\t+(\d+)\t+(.*)/);
        my ($size, $time, $name) = ($1, $2, centreon::plugins::misc::trim($3));
        my $diff_time = $current_time - $time;
        
        next if (defined($self->{option_results}->{filter_plugin}) && $self->{option_results}->{filter_plugin} ne '' &&
                 $name !~ /$self->{option_results}->{filter_plugin}/);
        
        my $exit_code = $self->{perfdata}->threshold_check(value => $diff_time, 
                                                           threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
        $self->{output}->output_add(long_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($time))));
        if (!$self->{output}->is_status(litteral => 1, value => $exit_code, compare => 'ok')) {
            $self->{output}->output_add(severity => $exit_code,
                                        short_msg => sprintf("%s: %s seconds (time: %s)", $name, $diff_time, scalar(localtime($time))));
        }
        $self->{output}->perfdata_add(label => $name, unit => 's',
                                      value => $diff_time,
                                      warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                      critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                      );
    }
      
    $self->{output}->display();
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

Check time (modified, creation,...) of files/directories.

=over 8

=item B<--files>

Files/Directories to check. (Shell expansion is ok)

=item B<--warning>

Threshold warning in seconds for each files/directories (diff time).

=item B<--critical>

Threshold critical in seconds for each files/directories (diff time).

=item B<--separate-dirs>

Do not include size of subdirectories.

=item B<--max-depth>

Don't check fewer levels. (can be use --separate-dirs)

=item B<--time>

Check another time than modified time.

=item B<--exclude-du>

Exclude files/directories with 'du' command. Values from exclude files/directories are not counted in parent directories.
Shell pattern can be used.

=item B<--filter-plugin>

Filter files/directories in the plugin. Values from exclude files/directories are counted in parent directories!!!
Perl Regexp can be used.

=item B<--remote>

Execute command remotely in 'ssh'.

=item B<--hostname>

Hostname to query (need --remote).

=item B<--ssh-option>

Specify multiple options like the user (example: --ssh-option='-l=centreon-engine' --ssh-option='-p=52').

=item B<--ssh-path>

Specify ssh command path (default: none)

=item B<--ssh-command>

Specify ssh command (default: 'ssh'). Useful to use 'plink'.

=item B<--timeout>

Timeout in seconds for the command (Default: 30).

=item B<--sudo>

Use 'sudo' to execute the command.

=item B<--command-path>

Command path (Default: none).

=back

=cut
