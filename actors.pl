#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Inline(
    'Java' => 'STUDY',
    STUDY     => ['java.util.concurrent.Semaphore','Ping','Pong'],
    AUTOSTUDY => 1,
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);

my $sema = java::util::concurrent::Semaphore->new(2);
$sema->acquire(2);

my $pong = Pong->new( $sema );
my $ping = Ping->new( $sema, 100000, $pong);

$ping->start;
$pong->start;

## blocks until threads are finished.
$sema->acquire(2);
