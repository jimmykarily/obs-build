################################################################
#
# Copyright (c) 2017 SUSE Linux Products GmbH
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License version 2 or 3 as
# published by the Free Software Foundation.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (see the file COPYING); if not, write to the
# Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA
#
################################################################

# TODO:
# - parse Dockerfile and extract dependecies
# - start docker daemon
# - import base image to the docker daemon
# - setup the dependencies directory
# - setup a zypper repository that will serve the dependecies directory
# - inject this repository as and ARG in the Dockerfile
# - build the Dockerfile
# - export the image tarball [OPTIONAL]

package Build::Docker;

use strict;

sub parse {
  my ($cf, $fn) = @_;

  # Perl slurp mode
  local $/=undef;
  open DOCKERFILE, $fn or die "Couldn't open Dockefile";
  my $dockerfile_data = <DOCKERFILE>;
  close DOCKERFILE;

  # Remove all whitespace from end of lines to make parsing easier
  $dockerfile_data =~ s/[^\S\n\r]+$//gm;

  my @deps = ();
  my $pkg_string;

  # Match lines that start with "RUN" up to where the "RUN" command ends. It
  # might span multiple lines if "\" is used (handled with negative lookbehind).
  # E.g.
  # RUN obs_install package1 package2 \
  #   package3
  while ($dockerfile_data =~ /(^\s*RUN(?:.|\n|\r)*?(?<!\\)$)/gm) {
    my $run_command = $1;

    # Remove the Dockerfile escape character and merge multiple lines in one.
    $run_command =~ s/\\(\n|\r)*//gm;

    # Match all obs_install commands up to the next command.
    # A command stops at ";" or "&" or end of line. E.g.
    #  RUN obs_install one \
    #   two && ls ; obs_install three
    while ($run_command =~ /obs_install\s+(.*?)(?:[;&]|$)/g) {
      $pkg_string = $1;
      my @packages = split(/\s+/, $pkg_string);
      if (0+@packages != 0) { push @deps, @packages; }
    }
  }

  # Find the base image to add it to dependencies
  if ($dockerfile_data =~ /^\s*FROM\s+(.*)$/gm) {
    push @deps, ("container://$1");
  }

  print STDERR "Dependencies: @deps \n";

  my $ret = {};
  $ret->{'deps'} = \@deps;

  return $ret;
}

1;
