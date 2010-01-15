#!/usr/bin/perl

use strict;
use warnings;
use Linux::ProcessInfo;

my @tree = Linux::ProcessInfo->tree($ARGV[0]);

sub pstree {
    my ($p, $i) = @_;

    printf("%10d %s\n",$p->pid, (' ' x $i) . $p->comm);
    for (sort { $a->starttime <=> $b->starttime } $p->children) {
        pstree($_,$i+1);
    } 
}

for (@tree) {
    pstree($_,0);
}
