use strict;
use warnings;
package MasonX::Compiler::Strict;
use parent 'HTML::Mason::Compiler::ToObject';
# ABSTRACT: an HTML::Mason compiler that can reject more input

=head1 OVERVIEW

This is an alternate compiler for HTML::Mason.  It's meant to fill in for the
default, L<HTML::Mason::Compiler::ToObject>.  (Don't trust things telling you
that the default is HTML::Mason::Compiler.  If you're using Mason, you're
almost certainly have ToObject doing the work.)

By default, it I<should> behave just like the normal compiler, but more options
can be provided to make it stricter.

Right now, there's just one extra option, but there will be more.

=attr allow_stray_content

If false, any text outside of a block (like a method or doc block), other than
blank lines, will be fatal.  Similar, any Perl lines other than comments will
be fatal.

This option is especially useful when used with L<MasonX::Component::RunMain>,
in which the component's body is in the C<main> method, not just "all the stuff
that wasn't in anything else."

=cut

use namespace::autoclean;

use HTML::Mason::Exceptions(abbr => [qw(param_error)]);

use Params::Validate qw(:all);
Params::Validate::validation_options(on_fail => sub {param_error join '', @_});

BEGIN {
  __PACKAGE__->valid_params(
    allow_stray_content => {
      parse => 'boolean',
      type  => SCALAR,
      default => 1,
      descr => "Whether to allow content outside blocks, or die",
    },
  );
}

sub text {
  my ($self, %arg) = @_;
  if (
    $self->{current_compile}{in_main}
    and ! $self->{allow_stray_content}
    and $arg{text} =~ /\S/
  ) {
    $self->lexer->throw_syntax_error(
      "text outside of block: <<'END_TEXT'\n$arg{text}END_TEXT"
    );
  }
  $self->SUPER::text(%arg);
}

sub perl_line {
  my ($self, %arg) = @_;

  if (
    $self->{current_compile}{in_main}
    and ! $self->{allow_stray_content}
    and $arg{line} !~ /\A\s*#/
  ) {
    $self->lexer->throw_syntax_error(
      "perl outside of block: $arg{line}\n"
    );
  }
  $self->SUPER::perl_line(%arg);
}

1;
