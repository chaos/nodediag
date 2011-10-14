package TAP::Formatter::Nodediag;

use strict;
use TAP::Formatter::Base ();
use TAP::Formatter::Nodediag::Session ();
use POSIX qw(strftime);
use File::Basename;

use vars qw($VERSION @ISA);

@ISA = qw(TAP::Formatter::Base);

$VERSION = '0.1';

sub open_test {
    my ( $self, $test, $parser ) = @_;

    my $session = TAP::Formatter::Nodediag::Session->new(
        {   name      => $test,
            formatter => $self,
            parser    => $parser,
        }
    );

    $session->header;

    return $session;
}

# no summary for nodediag
sub summary {
    return 0;
}

sub _should_show_count {
    return 0;
}

# Use _colorizer delegate to set output color. NOP if we have no delegate
sub _set_colors {
    my ( $self, @colors ) = @_;
    if ( my $colorizer = $self->_colorizer ) {
        my $output_func = $self->{_output_func} ||= sub {
            $self->_output(@_);
        };
        $colorizer->set_color( $output_func, $_ ) for @colors;
    }
}

sub _output_color {
    my ( $self, $color, $msg ) = @_;
    $self->_set_colors($color);
    $self->_output($msg);
    $self->_set_colors('reset');
}

1;
