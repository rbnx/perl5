################################################################################
#
#            !!!!!   Do NOT edit this file directly!   !!!!!
#
#            Edit mktests.PL and/or parts/inc/call instead.
#
#  This file was automatically generated from the definition files in the
#  parts/inc/ subdirectory by mktests.PL. To learn more about how all this
#  works, please read the F<HACKERS> file that came with this distribution.
#
################################################################################

use FindBin ();

BEGIN {
  if ($ENV{'PERL_CORE'}) {
    chdir 't' if -d 't';
    unshift @INC, '../lib' if -d '../lib' && -d '../ext';
    require Config; import Config;
    use vars '%Config';
    if (" $Config{'extensions'} " !~ m[ Devel/PPPort ]) {
      print "1..0 # Skip -- Perl configured without Devel::PPPort module\n";
      exit 0;
    }
  }

  use lib "$FindBin::Bin";
  use lib "$FindBin::Bin/../parts/inc";

  die qq[Cannot find "$FindBin::Bin/../parts/inc"] unless -d "$FindBin::Bin/../parts/inc";

  sub load {
    require 'testutil.pl';
    require 'inctools';
  }

  if (86) {
    load();
    plan(tests => 86);
  }
}

use Devel::PPPort;
use strict;
BEGIN { $^W = 1; }

package Devel::PPPort;
use vars '@ISA';
require DynaLoader;
@ISA = qw(DynaLoader);
bootstrap Devel::PPPort;

package main;

sub f
{
  shift;
  unshift @_, 'b';
  pop @_;
  @_, defined wantarray ? wantarray ? 'x' : 'y' : 'z';
}

my $obj = bless [], 'Foo';

sub Foo::meth
{
  return 'bad_self' unless @_ && ref $_[0] && ref($_[0]) eq 'Foo';
  shift;
  shift;
  unshift @_, 'b';
  pop @_;
  @_, defined wantarray ? wantarray ? 'x' : 'y' : 'z';
}

my $test;

for $test (
    # flags                      args           expected         description
    [ &Devel::PPPort::G_SCALAR,  [ ],           [ qw(y 1) ],     '0 args, G_SCALAR'  ],
    [ &Devel::PPPort::G_SCALAR,  [ qw(a p q) ], [ qw(y 1) ],     '3 args, G_SCALAR'  ],
    [ &Devel::PPPort::G_ARRAY,   [ ],           [ qw(x 1) ],     '0 args, G_ARRAY'   ],
    [ &Devel::PPPort::G_ARRAY,   [ qw(a p q) ], [ qw(b p x 3) ], '3 args, G_ARRAY'   ],
    [ &Devel::PPPort::G_DISCARD, [ ],           [ qw(0) ],       '0 args, G_DISCARD' ],
    [ &Devel::PPPort::G_DISCARD, [ qw(a p q) ], [ qw(0) ],       '3 args, G_DISCARD' ],
)
{
    my ($flags, $args, $expected, $description) = @$test;
    print "# --- $description ---\n";
    ok(eq_array( [ &Devel::PPPort::call_sv(\&f, $flags, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_sv(*f,  $flags, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_sv('f', $flags, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_pv('f', $flags, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_argv('f', $flags, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::eval_sv("f(qw(@$args))", $flags) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_method('meth', $flags, $obj, @$args) ], $expected));
    ok(eq_array( [ &Devel::PPPort::call_sv_G_METHOD('meth', $flags, $obj, @$args) ], $expected));
};

is(&Devel::PPPort::eval_pv('f()', 0), 'y');
is(&Devel::PPPort::eval_pv('f(qw(a b c))', 0), 'y');

is(!defined $::{'less::'}, 1, "Hadn't loaded less yet");
Devel::PPPort::load_module(0, "less", undef);
is(defined $::{'less::'}, 1, "Have now loaded less");

ok(eval { Devel::PPPort::eval_pv('die', 0); 1 });
ok(!eval { Devel::PPPort::eval_pv('die', 1); 1 });
ok($@ =~ /^Died at \(eval [0-9]+\) line 1\.\n$/);
ok(eval { $@ = 'string1'; Devel::PPPort::eval_pv('', 0); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_pv('', 1); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_pv('$@ = "string2"', 0); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_pv('$@ = "string2"', 1); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_pv('$@ = "string2"; die "string3"', 0); 1 });
ok(!eval { $@ = 'string1'; Devel::PPPort::eval_pv('$@ = "string2"; die "string3"', 1); 1 });
ok($@ =~ /^string3 at \(eval [0-9]+\) line 1\.\n$/);

if ("$]" >= '5.007003' or ("$]" >= '5.006001' and "$]" < '5.007')) {
    my $hashref = { key => 'value' };
    is(eval { Devel::PPPort::eval_pv('die $hashref', 1); 1 }, undef, 'check plain hashref is rethrown');
    is(ref($@), 'HASH', 'check $@ is hashref') and
        is($@->{key}, 'value', 'check $@ hashref has correct value');

    my $false = False->new;
    ok(!$false);
    is(eval { Devel::PPPort::eval_pv('die $false', 1); 1 }, undef, 'check false objects are rethrown');
    is(ref($@), 'False', 'check that $@ contains False object');
    is("$@", "$false", 'check we got the expected object');
} else {
    skip 'skip: no support for references in $@', 7;
}

ok(eval { Devel::PPPort::eval_sv('die', 0); 1 });
ok(!eval { Devel::PPPort::eval_sv('die', &Devel::PPPort::G_RETHROW); 1 });
ok($@ =~ /^Died at \(eval [0-9]+\) line 1\.\n$/);
ok(eval { $@ = 'string1'; Devel::PPPort::eval_sv('', 0); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_sv('', &Devel::PPPort::G_RETHROW); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_sv('$@ = "string2"', 0); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_sv('$@ = "string2"', &Devel::PPPort::G_RETHROW); 1 });
ok(eval { $@ = 'string1'; Devel::PPPort::eval_sv('$@ = "string2"; die "string3"', 0); 1 });
ok(!eval { $@ = 'string1'; Devel::PPPort::eval_sv('$@ = "string2"; die "string3"', &Devel::PPPort::G_RETHROW); 1 });
ok($@ =~ /^string3 at \(eval [0-9]+\) line 1\.\n$/);

if ("$]" >= '5.007003' or ("$]" >= '5.006001' and "$]" < '5.007')) {
    my $hashref = { key => 'value' };
    is(eval { Devel::PPPort::eval_sv('die $hashref', &Devel::PPPort::G_RETHROW); 1 }, undef, 'check plain hashref is rethrown');
    is(ref($@), 'HASH', 'check $@ is hashref') and
        is($@->{key}, 'value', 'check $@ hashref has correct value');

    my $false = False->new;
    ok(!$false);
    is(eval { Devel::PPPort::eval_sv('die $false', &Devel::PPPort::G_RETHROW); 1 }, undef, 'check false objects are rethrown');
    is(ref($@), 'False', 'check that $@ contains False object');
    is("$@", "$false", 'check we got the expected object');
} else {
    skip 'skip: no support for references in $@', 7;
}

{
    package False;
    use overload bool => sub { 0 }, '""' => sub { 'Foo' };
    sub new { bless {}, shift }
}

