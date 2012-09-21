use strict;
use warnings;
package MasonX::MainMethod::Component;
use parent 'HTML::Mason::Component::FileBased';

sub run {
  my $self = shift;
  $self->call_method(main => @_);
}

1;
