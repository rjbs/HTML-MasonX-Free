#!perl
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use MasonX::Compiler::Strict;
use MasonX::Resolver::AutoInherit;
use MasonX::Component::RunMain;

my $interp = HTML::Mason::Interp->new(
  # This works, too. -- rjbs, 2012-09-20
  # compiler_class => 'MasonX::Compiler::Strict',
  # allow_stray_content => 0,
  comp_root => '/-',
  compiler  => MasonX::Compiler::Strict->new(default_method_to_call => 'main'),
  resolver  => MasonX::Resolver::AutoInherit->new({
    comp_class => 'MasonX::Component::RunMain',
    resolver_roots  => [
      [ comp_root => dir('mason/runmain')->absolute->stringify ],
    ],
  }),
);

sub output_for {
  my ($path) = @_;

  return unless my $comp = $interp->load( $path );

  my $output;

  $interp->make_request(
    comp => $comp,
    args => [
      mood => 'grumpy',
      mood => 'bored',
      tea  => 'weak',
    ],
    out_method => \$output,
  )->exec;

  1 while chomp $output;
  $output;
}

sub output_is {
  my ($path, $output) = @_;
  local $Test::Builder::Level = $Test::Builder::Level + 1;
  is( output_for($path), $output, $path);
}

output_is('/well-behaved',   "This is the main method.");
output_is('/doc-section',    "This is the main method.");
output_is('/commented-perl', "This is the main method.");
output_is('/extra-blanks',   "This is the main method.");
output_is('/extra-text',     "This is the main method.");
output_is('/extra-perl',     "This is the main method.");

output_is('/calls-wb',       "This is the main method.");

output_is('/revrev-method',  "This is the main method.");
output_is('/revrev',         "This is the main method.");

done_testing;
