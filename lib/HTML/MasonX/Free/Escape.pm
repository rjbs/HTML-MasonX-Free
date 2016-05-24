use strict;
use warnings;
package HTML::MasonX::Free::Escape;
# ABSTRACT: default HTML escaping with an escape hatch

=head1 OVERVIEW

First, when you set up your compiler, you pass:

  default_escape_flags => 'html'

Then, when you set up your interpreter, you redefine the html handler(s):

  use HTML::MasonX::Free::Escape qw(html_escape);
  $interp->set_escape('h' => \&html_escape);
  $interp->set_escape('html' => \&html_escape);

Finally, for good measure, get C<html_hunk> imported to your Commands package:

  package HTML::Mason::Commands { use HTML::MasonX::Free::Escape 'html_hunk' }

Now, by default, when you do this in a template:

  The best jelly is <% $flavor %> jelly.

...the C<$flavor> will be HTML entity escaped.  If you want to deal with
variables that are I<not> going to be escaped, you use C<html_hunk>:

  Here's some math: <% html_hunk( $eqn->as_mathml ) %>

Even though it's called C<html_hunk>, it just means "don't HTML escape this."
If you put in some XML, you won't get in trouble.  The result of calling
C<html_hunk> is an object that will throw an exception if stringified.  This
prevents you from making mistakes like:

  my $target = html_hunk("world");
  my $greet  = "Hello, $target";

=cut

use Exporter 'import';
use Scalar::Util qw(blessed);

our @EXPORT_OK = qw(html_escape html_hunk);

{
  package
    HTML::MasonX::Free::HTMLHunk;
  use Carp ();
  sub new { my ($class, $str) = @_; bless \$str, $class }
  sub as_html { ${ $_[0] } }
  use overload
    '""' => sub { Carp::confess("HTML hunk stringified: <${$_[0]}>") },
      fallback => 1;
}

# mostly taken from HTML::Mason::Escapes except it adds "'"
my $HTML_ESCAPE = qr/([&<>"'])/;
my %HTML_ESCAPE = (
  '&' => '&amp;',
  '>' => '&gt;',
  '<' => '&lt;',
  '"' => '&quot;',
  "'" => '&#39;'
);

sub html_escape {
  my $ref = $_[0];
  return unless defined $$ref;

  if (blessed $$ref and $$ref->isa('HTML::MasonX::Free::HTMLHunk')) {
    $$ref = $$ref->as_html;
    return;
  }

  $$ref =~ s/$HTML_ESCAPE/$HTML_ESCAPE{$1}/mg;
}

sub html_hunk {
  return HTML::MasonX::Free::HTMLHunk->new($_[0]);
}

1;
