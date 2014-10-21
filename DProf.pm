package Apache::DProf;

use strict;
use Carp;
use vars qw($VERSION @ISA);
use Cwd ();
use File::Path ();
use DynaLoader ();

@ISA = qw(DynaLoader);

$VERSION = '0.01';

bootstrap Apache::DProf $VERSION;

if($ENV{MOD_PERL}) {
    my $path = Apache->server_root_relative("logs/dprof");

    File::Path::rmtree($path);

    Apache->push_handlers(PerlChildInitHandler => \&handler);
}

sub prof_path {
    shift->server_root_relative("logs/dprof/$$")
}

sub handler {
    my $r = shift;
    my $cwd = Cwd::fastcwd();
    my $dir = prof_path($r);
    File::Path::mkpath($dir);
    chdir $dir;

    #$ENV{PERL5DB} = "use Devel::DProf;";

    if(init_debugger()) {
	warn "[notice] Apache::DProf->init_debugger in child $$\n";
    }
    else {
	warn "[notice] Apache::DProf entering child $$\n";
    }

    require Devel::DProf;

    init_DBsub();

    chdir $cwd;

    #need mod_perl 1.08+ for push'd ChildExitHandler's to work,
    #but this isn't required
    #$r->push_handlers(PerlChildExitHandler => \&exit_handler);

    return 0;
}

sub exit_handler {
    my $r = shift;
    my $dir = prof_path($r);
    chdir $dir; 

    warn "[notice] Apache::DProf exiting child $$\n";
    return 0;
}

1;
__END__

=head1 NAME

Apache::DProf - Hook Devel::DProf into mod_perl

=head1 SYNOPSIS

 #in httpd.conf
 PerlModule Apache::DProf

=head1 DESCRIPTION

The Apache::DProf module will run a Devel::DProf profiler inside each
child server and write the I<tmon.out> file in the directory
I<$ServerRoot/logs/dprof/$$> when the child is shutdown.
Next time the parent server pulls in Apache::DProf (via soft or hard
restart), the I<$ServerRoot/logs/dprof> is cleaned out before new
profiles are written for the new children.

=head1 WHY

It is possible to profile code run under mod_perl with only the
B<Devel::DProf> module available on CPAN.  You must have
apache version 1.3b3 or higher.  When the server is started,
B<Devel::DProf> installs an C<END> block to write the I<tmon.out>
file, which will be run when the server is shutdown.  Here's how to
start and stop a server with the profiler enabled:

 % setenv PERL5OPT -d:DProf
 % httpd -X -d `pwd` &
 ... make some requests to the server here ...
 % kill `cat logs/httpd.pid`
 % unsetenv PERL5OPT
 % dprofpp

There are downsides to this approach:  

- Setting and unsetting PERL5OPT is a pain.

- Server startup code will be profiled as well, which we are not
  really concerned with, we're interested in runtime code, right?

- It will not work unless the server is run in non-forking C<-X> mode

These limitations are due to the assumption by Devel::DProf that the
code you are profiling is running under a standard Perl binary (the
one you run from the command line).  C<Devel::Dprof> relies on the
Perl C<-d> switch for intialization of the Perl debugger, which
happens inside C<perl_parse()> function call.  It also relies on
Perl's special C<END> subroutines for termination when it writes the
raw profile to I<tmon.out>.  Under the standard command line Perl
interpreter, these C<END> blocks are run when the C<perl_run()>
function is called.  Also, Devel::DProf will not profile any code if
it is inside a forked process.  Each time you run a Perl script from
the command line, the C<perl_parse()> and C<perl_run()> functions are
called, Devel::DProf works just fine this way.

Under mod_perl, the C<perl_parse()> and C<perl_run()> functions are
called only once, when the parent server is starting.  Any C<END>
blocks encountered during server startup or outside of
C<Apache::Registry> scripts are suspended and run when the server is
shutdown via apache's child exit callback hook.  The parent server
only runs Perl startup code, all request time code is run in the
forked child processes.  If you followed the previous paragraph, you
should be able to see, Devel::DProf does not fit into the mod_perl
model too well.  The Apache::DProf module exists to make it fit
without modifying the Devel::DProf module or Perl itself.

The B<Apache::DProf> module also requires apache version 1.3b3 or
higher and C<PerlChildInitHandler> enabled.  It is configured simply
by adding this line to your httpd.conf file: 

 PerlModule Apache::DProf

When the Apache::DProf module is pulled in by the parent server, it
will push a C<PerlChildInitHandler> via the Apache push_handlers
method.  When a child server is starting the C<Apache::DProf::handler>
subroutine will called.  This handler will create a directory
C<dprof/$$> relative to B<ServerRoot> where Devel::DProf will create
it's I<tmon.out> file.  Then, the handler will initialize the Perl
debugger and pull in Devel::DProf who will then install it's hooks
into the debugger and start it's profile timer.  The C<END> subroutine
installed by Devel::DProf will be run when the child server is
shutdown and the I<$ServerRoot/dprof/$$/tmon.out> file will be
generated and ready for B<dprofpp>.

=head1 AUTHOR

Doug MacEachern

=head1 SEE ALSO

Devel::DProf(3), mod_perl(3), Apache(3)

=cut
