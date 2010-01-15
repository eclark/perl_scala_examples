#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Inline(
    'Java' => <<'END',
public class BooleanCondVar extends CondVar<Boolean> {
}

END
    STUDY     => ['CondVar','Ping','Pong'],
    AUTOSTUDY => 1,
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);
use Inline::Java qw(caught);

my $cv = BooleanCondVar->new;

my $pong = Pong->new( $cv );
my $ping = Ping->new( $cv, 100000, $pong);

$ping->start;
$pong->start;

## blocks until threads are finished.
eval {
    my $v = $cv->recv;
};
if ($@) {
    if (caught("java.lang.Exception")) {
        my $msg = $@->getMessage();
        print $msg . "\n";
        print Dumper($@);
    } else {
        die $@;
    }
} 
