#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Inline(
    'Java' => 'STUDY',
    STUDY     => ['Ping','Pong','Semaphore'],
    AUTOSTUDY => 1,
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);

my $sema = Semaphore->new;

$sema->incr;
$sema->incr;

my $pong = Pong->new( $sema );
my $ping = Ping->new( $sema, 100000, $pong);

$ping->start;
$pong->start;

while ($sema->count > 0) {
    usleep 1000;
} 
