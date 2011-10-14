package TAP::Formatter::Nodediag::Session;

use strict;
use TAP::Formatter::Session;
use File::Basename;

use vars qw($VERSION @ISA);

@ISA = qw(TAP::Formatter::Session);

$VERSION = '0.1';

# called for each line of ouptut - accumulate raw output
sub result {
    my $self   = shift;
    my $result = shift;

    my $parser    = $self->parser;
    my $formatter = $self->formatter;
    my $name      = basename ($self->name);

    $self->{results} .= $self->_format_for_output($result) . "\n";
}

sub close_test {
    my $self = shift;

    # Avoid circular references
    $self->parser(undef);

    my $parser    = $self->parser;
    my $formatter = $self->formatter;
    my $name      = basename ($self->name);

    $name =~ s/\.t$//; # drop the .t suffix from test name

    return if $formatter->really_quiet;
    return if $formatter->quiet && !$parser->has_problems;

    $formatter->_output (sprintf "%-60s", "Checking $name:" );
    if ( $parser->has_problems ) {
        $formatter->_output_color ( 'red',    "[ FAIL ]\n");
    } elsif ( $parser->skip_all || $parser->skipped > 0) {
        $formatter->_output_color ( 'yellow', "[NOTRUN]\n" );
    } else {
        $formatter->_output_color ( 'green',  "[  OK  ]\n");
    }

    # Dump raw output for this test if verbose
    if ($formatter->verbose) {
        $formatter->_output ( ( $self->{results} ? $self->{results} : "\n" ) );
    }

    if ($parser->has_problems && $main::conf{firstfail}) {
        exit 1;
    }
}

1;
