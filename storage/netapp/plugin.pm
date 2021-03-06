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

package storage::netapp::plugin;

use strict;
use warnings;
use base qw(centreon::plugins::script_snmp);

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;
    # $options->{options} = options object

    $self->{version} = '1.0';
    %{$self->{modes}} = (
                         'cp-statistics'    => 'storage::netapp::mode::cpstatistics',
                         'cpuload'          => 'storage::netapp::mode::cpuload',
                         'diskfailed'       => 'storage::netapp::mode::diskfailed',
                         'fan'              => 'storage::netapp::mode::fan',
                         'filesys'          => 'storage::netapp::mode::filesys',
                         'global-status'    => 'storage::netapp::mode::globalstatus',
                         'list-filesys'     => 'storage::netapp::mode::listfilesys',
                         'ndmpsessions'     => 'storage::netapp::mode::ndmpsessions',
                         'nvram'            => 'storage::netapp::mode::nvram',
                         'partnerstatus'    => 'storage::netapp::mode::partnerstatus',
                         'psu'              => 'storage::netapp::mode::psu',
                         'share-calls'      => 'storage::netapp::mode::sharecalls',
                         'shelf'            => 'storage::netapp::mode::shelf',
                         'snapmirrorlag'    => 'storage::netapp::mode::snapmirrorlag',
                         'temperature'      => 'storage::netapp::mode::temperature',
                         'volumeoptions'    => 'storage::netapp::mode::volumeoptions',
                         'aggregatestate'   => 'storage::netapp::mode::aggregatestate',
                         'snapshotage'      => 'storage::netapp::mode::snapshotage',
                         );

    return $self;
}

1;

__END__

=head1 PLUGIN DESCRIPTION

Check Netapp in SNMP (Some Check needs ONTAP 8.x).

=cut
