#!/usr/bin/env perl

use strict;
use warnings;
use Time::HiRes qw/usleep/;
use Inline(
    'Java' => 'STUDY',
    STUDY     => ['Linux.ProcessInfo'],
    AUTOSTUDY => 1,
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);

print Linux::ProcessInfo->funkytown . "\n";

