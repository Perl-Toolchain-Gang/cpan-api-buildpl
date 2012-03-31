# vim:tw=72:
use strict;
use warnings;
package CPAN::API::BuildPL;
# ABSTRACT: Documentation of the API for using Build.PL

1;

__END__

=begin wikidoc

= DESCRIPTION

*THIS DOCUMENT IS STILL A ROUGH DRAFT*

This documentation describes an API for how a Build.PL file in a Perl
distribution may be used to build and install the distribution.  This is
primarily of interest to CPAN clients like [CPAN], [CPANPLUS] and
[cpanm].

While Build.PL originated with [Module::Build], there is no reason that
alternative pure-Perl build systems can't use the same mechanism.  With
the {configure_requires} key in distribution META files supported in the
Perl core since version 5.10.1, it will be increasingly easy over time
for other pure-Perl build system to flourish.

The terms *must*, *should*, *may* and their negations have the usual
IETF semantics.

The API described herein is a minimal feature sufficient for basic
interoperability between a CPAN client and a pure-Perl build system to
build, test and install Perl distributions.  Any build system *must*
provide all of the features. The build system *may* provide additional
features, but CPAN clients *should not* rely on them.

Portions of this document have been copied or adapted from the
documentation of [Module::Build] (copyright Ken Williams).

= USAGE

== Build.PL program

  perl Build.PL [options]

* if run with a '--build-pl-api-version' option, *must* print on a single line to STDOUT
the Build.PL API version supported and *must* exit with 0; it *must not* do
any other processing described below; it *may* say what 
* *must* generate a Build file if configuration is successful
* *must* exit with exit code of zero if configuration is successful
* *must* not generate a Build file if configuration fails
* *may* exit with a zero or non-zero exit code; clients *may* interpret
a zero exit code with no Build file produced as a request to abort
further action without signaling error to the user
* *must* generate at least one MYMETA file following a version of the
CPAN::Meta::Spec
* *may* print warnings about unsatisfied prerequisties to STDOUT
* *must* accept user configuration as described in this document
* *must* cache user configuration for later use by 'Build'

== Build program

  ./Build [command] [options]

* *must* carry out a 'build' action if no command is specified
* *must* use the same perl executable that was used to run Build.PL
* *should not* preserve @INC from Build.PL

A list of actions that *must* be supported follows:

=== 'build' action

* *must* prepare the distribution for the test and install actions
* *must* exit with 0 if the distribution is considered ready for
testing/installation
* *must* exit with a non-zero code if the distribution is not ready 
for testing/installation

Historically, this means compiling, copying files to blib, etc.
and many existing tools may expect to find things in blib.  This is
not necessarily the right way to do thing forever and ever.

=== 'test' action

(Add purpose statement?)

* *must* exit with 0 if the distribution is considered install-ready
* *must* exit with a non-zero code if the distribution is not ready to
install
* *should* produce a human-readable result to STDOUT
* *may* run the 'build' action
* *may* consider having no tests to be a successful result

=== 'install' action

* *must* exit with 0 if the distribution was installed successfully
* *must* exit with a non-zero code if the distribution was not installed
successfully
* *must* install to the paths defined in other sections of this document
* *should* not modify paths not defined in other sections of this
document
* *should* preserve the prior state of the system if installation is
unsuccessful 
* *must not* require the test action to have been run

= CONFIGURATION

(blah blah configuration blah blah)

During execution of Build.PL or Build, options should have the following
precedence (from high to low):

* {@ARGV}
* {$ENV{PERL_MB_OPT}}
* configuration file -- action-specific options
* cached configuration from Build.PL (only when running Build)
* configuration file -- wildcard (*)
*

Conceptually, options should be split on white space and then spliced
together, with higher-precedence options following lower-precedence
options.  Options should then be processed "in order".

== Command Line Options

(write about them here, if only to refer to INSTALL_PATHS)

Initial thoughts:

* --dest_dir
* --installdirs
* --install_base
* --install_path
* --uninst
* --verbose (?) (but connects to EU::Install)
* --quiet (?)

== Configuration file

When Build.PL or Build runs, it *must* look for a configuration file
in the following locations and *must* take the first file that it finds,
if more than one exists:

  $ENV{MODULEBUILDRC}
  $ENV{HOME} . "/.modulebuildrc"
  $ENV{USERPROFILE} . "/.modulebuldrc"

If a configuration file exists, the options specified there *must* used
as defaults as if they were typed on the command line, but the actual
command line *must* override defaults from a configuration file.  The
format of the configuration file is described below.

As with Perl, a hash mark ({#}) begins a comment that continues to the
end of the line it appears on.  Comments *must* be ignored.  Empty lines
or lines with only white space *must* also be ignored.

The first word on a configuration line describe the 'action' to which
the options apply.  The 'action' is the command given to the 'Build'
program.  An action *must* be followed by whitespace and then the
options.  Options *must* be formed just as they would be on the command
line (e.g.  separated by whitespace).  They can be separated by any
amount of whitespace, including newlines, as long there is whitespace at
the beginning of each continued line.  If more than one line begins with
the same action name, those lines are merged into one set of options in
the order they appear.

There are three special pseudo-actions: an {*} (asterisk) denotes global
options that *must* be applied whenever 'Build.PL' or 'Build' is run,
the pseudo-action 'build' *must* be applied when 'Build' is run without
a command like 'test' or 'install', and the key 'Build_PL' specifies
options that *must* be applied when 'Build.PL' is run.

For example:

  *           --verbose   # global options
  install     --install_base /home/ken
              --install_path html=/home/ken/docs/html

Unrecognized actions *should* be ignored and *must not* be treated as
errors.

== Environment variables

* MODULEBUILDRC -- specifies the preferred location of a configuration
file
* PERL_MB_OPT -- provides option as if they were specified on the command
line to Build.PL or any Build action, but with precedence lower than
actual command line options .  The string *must* be split on whitespace
as the shell would and the result prepended to any actual command-line
arguments in {@ARGV}


=end wikidoc

=head1 INSTALL PATHS

When you invoke C<Build>, it needs to figure
out where to install things.  The nutshell version of how this works
is that default installation locations are determined from
F<Config.pm>, and they may be overridden by using the C<install_path>
parameter.  An C<install_base> parameter lets you specify an
alternative installation root like F</home/foo>, and a C<destdir> lets
you specify a temporary installation directory like F</tmp/install> in
case you want to create bundled-up installable packages.

A build system *must* provide default installation locations for
the following types of installable items:

=over 4

=item lib

Usually pure-Perl module files ending in F<.pm>.

=item arch

"Architecture-dependent" module files, usually produced by compiling
XS, L<Inline>, or similar code.

=item script

Programs written in pure Perl.  In order to improve reuse, try to make
these as small as possible - put the code into modules whenever
possible.

=item bin

"Architecture-dependent" executable programs, i.e. compiled C code or
something.  Pretty rare to see this in a perl distribution, but it
happens.

=item bindoc

Documentation for the stuff in C<script> and C<bin>.  Usually
generated from the POD in those files.  Under Unix, these are manual
pages belonging to the 'man1' category.

=item libdoc

Documentation for the stuff in C<lib> and C<arch>.  This is usually
generated from the POD in F<.pm> files.  Under Unix, these are manual
pages belonging to the 'man3' category.

=item binhtml

This is the same as C<bindoc> above, but applies to HTML documents.

=item libhtml

This is the same as C<bindoc> above, but applies to HTML documents.

=back

Five other parameters let you control various aspects of how
installation paths are determined:

=over 4

=item installdirs

The default destinations for these installable things come from
entries in your system's C<Config.pm>.  You can select from three
different sets of default locations by setting the C<installdirs>
parameter as follows:

                          'installdirs' set to:
                   core          site                vendor

              uses the following defaults from Config.pm:

  lib     => installprivlib  installsitelib      installvendorlib
  arch    => installarchlib  installsitearch     installvendorarch
  script  => installscript   installsitebin      installvendorbin
  bin     => installbin      installsitebin      installvendorbin
  bindoc  => installman1dir  installsiteman1dir  installvendorman1dir
  libdoc  => installman3dir  installsiteman3dir  installvendorman3dir
  binhtml => installhtml1dir installsitehtml1dir installvendorhtml1dir [*]
  libhtml => installhtml3dir installsitehtml3dir installvendorhtml3dir [*]

  * Under some OS (eg. MSWin32) the destination for HTML documents is
    determined by the C<Config.pm> entry C<installhtmldir>.

The default value of C<installdirs> is "site".  If you're creating
vendor distributions of module packages, you may want to do something
like this:

  perl Build.PL --installdirs vendor

or

  ./Build install --installdirs vendor

If you're installing an updated version of a module that was included
with perl itself (i.e. a "core module"), then you may set
C<installdirs> to "core" to overwrite the module in its present
location.

=item install_path

Once the defaults have been set, you can override them.

On the command line, that would look like this:

  perl Build.PL --install_path lib=/foo/lib --install_path arch=/foo/lib/arch

or this:

  ./Build install --install_path lib=/foo/lib --install_path arch=/foo/lib/arch

=item install_base

You can also set the whole bunch of installation paths by supplying the
C<install_base> parameter to point to a directory on your system.  For
instance, if you set C<install_base> to "/home/ken" on a Linux
system, you'll install as follows:

  lib     => /home/ken/lib/perl5
  arch    => /home/ken/lib/perl5/i386-linux
  script  => /home/ken/bin
  bin     => /home/ken/bin
  bindoc  => /home/ken/man/man1
  libdoc  => /home/ken/man/man3
  binhtml => /home/ken/html
  libhtml => /home/ken/html

=item destdir

If you want to install everything into a temporary directory first
(for instance, if you want to create a directory tree that a package
manager like C<rpm> or C<dpkg> could create a package from), you can
use the C<destdir> parameter:

  perl Build.PL --destdir /tmp/foo

or

  ./Build install --destdir /tmp/foo

This will effectively install to "/tmp/foo/$sitelib",
"/tmp/foo/$sitearch", and the like, except that it will use
C<File::Spec> to make the pathnames work correctly on whatever
platform you're installing on.

=item prefix

An implementation *may* implement this option for compatibility with ExtUtils::MakeMaker's PREFIX argument. If implemented it *must* behave the same as ExtUtils::MakeMaker 6.30 would given the PREFIX argument. In other words, the following examples must be equivalent.

 perl Build.PL --prefix /tmp/foo
 perl Makefile.PL PREFIX=/tmp/foo

If an implementation opts not implement prefix, it *must* give a descriptive error at the earliest possible time if a user tries to use it.

=back

=begin wikidoc

= SEE ALSO

* [CPAN]
* [CPANPLUS]
* [cpanm]
* [Module::Build]
* [Acme::Module::Build::Tiny]

=end wikidoc

=cut

