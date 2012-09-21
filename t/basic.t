#!perl
use strict;
use warnings;

use Test::Fatal;
use Test::More;

use Path::Class qw(dir);
use HTML::Mason::Interp;
use MasonX::MainMethod::Component;
use MasonX::MainMethod::Compiler;

{
  # It's ridiculous that I "had to" copy so much of this, but I did.
  # -- rjbs, 2012-09-20
  package StupidResolver;
  use parent 'HTML::Mason::Resolver::File';

  use HTML::Mason::Tools qw(read_file_ref paths_eq);

  sub get_info {
    my ($self, $path, $comp_root_key, $comp_root_path) = @_;

    # Note that canonpath has the property of not collapsing a series
    # of /../../ dirs in an unsafe way. This means that if the
    # component path is /../../../../etc/passwd, we're still safe. I
    # don't know if this was intentional, but it's certainly a good
    # thing, and something we want to preserve if the code ever
    # changes.
    my $srcfile = File::Spec->canonpath( File::Spec->catfile( $comp_root_path, $
path ) );
    return unless -f $srcfile;
    my $modified = (stat _)[9];
    my $base = $comp_root_key eq 'MAIN' ? '' : "/$comp_root_key";
    $comp_root_key = undef if $comp_root_key eq 'MAIN';

    return
      HTML::Mason::ComponentSource->new
          ( friendly_name => $srcfile,
            comp_id => "$base$path",
            last_modified => $modified,
            comp_path => $path,
            comp_class => 'MasonX::MainMethod::Component',
            extra => { comp_root => $comp_root_key },
            source_callback => sub { read_file_ref($srcfile) },
          );
  }
}

my $interp = HTML::Mason::Interp->new(
  comp_root => dir('mason')->absolute->stringify,
  resolver_class => 'StupidResolver',
  compiler_class => 'MasonX::MainMethod::Compiler',
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

{
  my $error = exception { output_for('/extra-text') };
  like($error, qr/text outside of block/, "we fatalized stray text");
}

{
  my $error = exception { output_for('/extra-perl') };
  like($error, qr/perl outside of block/, "we fatalized stray perl");
}

done_testing;
