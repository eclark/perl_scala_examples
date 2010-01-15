#!/usr/bin/env perl

use strict;
use warnings;
use Inline(
    'Java'    => 'STUDY',
    STUDY     => ['Linux.ProcessInfo'],
    AUTOSTUDY => 1,
    PACKAGE   => 'j',
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);
use Data::Dumper;

my $o = j::Linux::ProcessInfo->new($$);

print Dumper($o);

print $o->pid . "\n";
