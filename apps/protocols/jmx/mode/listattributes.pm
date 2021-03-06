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

package apps::protocols::jmx::mode::listattributes;

use base qw(centreon::plugins::mode);

use strict;
use warnings;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    
    $self->{version} = '1.0';
    $options{options}->add_options(arguments =>
                                {
                                  "max-depth:s"             => { name => 'max_depth', default => 6 },
                                  "max-objects:s"           => { name => 'max_objects', default => 10000 },
                                  "max-collection-size:s"   => { name => 'max_collection_size', default => 150 },
                                  "mbean-pattern:s"         => { name => 'mbean_pattern', default => '*:*' },
                                });
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

}

sub run {
    my ($self, %options) = @_;
    $self->{connector} = $options{custom};

    $self->{connector}->list_attributes(%{$self->{option_results}});
    $self->{output}->exit();
}

1;

__END__

=head1 MODE

List JMX attributes.

=over 8

=item B<--max-depth>

Maximum nesting level of the returned JSON structure for a certain MBean (Default: 6)

=item B<--max-collection-size>

Maximum size of a collection after which it gets truncated (default: 150)

=item B<--max-objects>

Maximum overall objects to fetch for a mbean (default: 10000)

=item B<--mbean-pattern>

Pattern matching (Default: '*:*').
For details: http://docs.oracle.com/javase/1.5.0/docs/api/javax/management/ObjectName.html

=back

=cut
