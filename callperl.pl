#!/usr/bin/env perl

use strict;
use warnings;
use Inline(
    'Java' => 'STUDY',
    STUDY     => ['HelpMePerl'],
    AUTOSTUDY => 1,
    CLASSPATH => $ENV{SCALA_HOME} . '/lib/scala-library.jar:.'
);

my $h = HelpMePerl->new();

my $z = $h->xmatch('abcdefg','xxd');

print "$z\n";
