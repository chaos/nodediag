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

    # Harness defined verbosity values are:
    #  1:  verbose, add raw test results
    #  0:  normal, show invividual test results
    # -1:  quiet, show only failed individual test results
    # -2:  really_quiet, suppress all but summary
    # -3:  silent, suppress everything
    # We have to respect these values so we can run under prove.
    # However we do sneak in some flags (avoiding bitwise ops since we have
    # a signed integer) that allow nodeattr -vx (verbose fail only) and
    # nodeattr -f (exit on first fail).
    #
    my $verbosity = $formatter->verbosity;
    my $firstfail = $verbosity >= 0x20 - 3 ? 1 : 0;
    $verbosity -= 0x20 if $firstfail;
    my $verbose = $verbosity >= 0x10 - 3 ? 1 : 0;
    $verbosity -= 0x10 if $verbose;
    
    if ($verbosity > -2) {
        if ($verbosity > -1 || $parser->has_problems) {
            $formatter->_output (sprintf "%-60s", "Checking $name:" );
            if ( $parser->has_problems ) {
                $formatter->_output_color ( 'red',    "[ FAIL ]\n");
            } elsif ( $parser->skip_all || $parser->skipped > 0) {
                $formatter->_output_color ( 'yellow', "[NOTRUN]\n" );
            } else {
                $formatter->_output_color ( 'green',  "[  OK  ]\n");
            }
            if ($verbosity >= 1 || $verbose) {
                $formatter->_output ($self->{results} ? $self->{results} :"\n");
            }
        }
    }
    # Arguably this is wrong but we are fighting Tap::Harness here
    if ($parser->has_problems && $firstfail) {
        exit 1;
    }
}

# vi: ts=4 sw=4 expandtab

1;
