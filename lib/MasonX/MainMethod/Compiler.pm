use strict;
use warnings;
package MasonX::MainMethod::Compiler;
use parent 'HTML::Mason::Compiler::ToObject';

use namespace::autoclean;

use HTML::Mason::Exceptions(
  abbr => [qw(param_error compiler_error syntax_error)]
);

use Params::Validate qw(:all);
Params::Validate::validation_options(on_fail => sub {param_error join '', @_});

BEGIN {
  __PACKAGE__->valid_params(
    ignore_stray_content => {
      parse => 'boolean',
      type  => SCALAR,
      default => 0,
      descr => "Whether to ignore content outside blocks, or die",
    },
  );
}

sub text {
  my ($self, %arg) = @_;
  if (
    $self->{current_compile}{in_main}
    and ! $self->{ignore_stray_content}
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
    and ! $self->{ignore_stray_content}
    and $arg{line} !~ /\A\s*#/
  ) {
    $self->lexer->throw_syntax_error(
      "perl outside of block: $arg{line}\n"
    );
  }
  $self->SUPER::perl_line(%arg);
}

1;
