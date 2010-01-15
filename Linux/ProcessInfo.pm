package Linux::ProcessInfo;

use strict;
use warnings;

use Carp qw/croak/;
use Fcntl;
use Sub::Install;
use POSIX;
use AnyEvent::AIO;
use IO::AIO;

our $rblk = 128;
our $max_fd = 50;

sub USE_FORMATS () { 0; }

my @config = (
    'stat' => [
        pid                   => \&__no_fmt,
        comm                  => \&__no_fmt,
        state                 => \&__no_fmt,
        ppid                  => \&__no_fmt,
        pgrp                  => \&__no_fmt,
        session               => \&__no_fmt,
        tty_nr                => \&__no_fmt,
        tpgid                 => \&__no_fmt,
        flags                 => \&__no_fmt,
        minflt                => \&__no_fmt,
        cminflt               => \&__no_fmt,
        majflt                => \&__no_fmt,
        cmajflt               => \&__no_fmt,
        utime                 => \&__no_fmt,
        stime                 => \&__no_fmt,
        cutime                => \&__no_fmt,
        cstime                => \&__no_fmt,
        priority              => \&__no_fmt,
        nice                  => \&__no_fmt,
        num_threads           => \&__no_fmt,
        itrealvalue           => \&__no_fmt,
        starttime             => \&__no_fmt,
        vsize                 => \&__no_fmt,
        rss                   => \&__no_fmt,
        rlim                  => \&__no_fmt,
        startcode             => \&__no_fmt,
        endcode               => \&__no_fmt,
        startstack            => \&__no_fmt,
        kstkesp               => \&__no_fmt,
        kstkeip               => \&__no_fmt,
        signal                => \&__no_fmt,
        blocked               => \&__no_fmt,
        sigignore             => \&__no_fmt,
        sigcatch              => \&__no_fmt,
        wchan                 => \&__no_fmt,
        nswap                 => \&__no_fmt,
        cnswap                => \&__no_fmt,
        exit_signal           => \&__no_fmt,
        processor             => \&__no_fmt,
        rt_priority           => \&__no_fmt,
        policy                => \&__no_fmt,
        delayacct_blkio_ticks => \&__no_fmt
    ],
    'statm' => [
        size     => \&__no_fmt,
        resident => \&__no_fmt,
        share    => \&__no_fmt,
        text     => \&__no_fmt,
        lib      => \&__no_fmt,
        data     => \&__no_fmt,
        dt       => \&__no_fmt
    ]
);

sub __no_fmt {
    $_[0];
}

sub pagesize {
    my $ps = POSIX::sysconf(&POSIX::_SC_PAGESIZE);
    return defined $ps ? $ps : POSIX::sysconf(&POSIX::_SC_PAGE_SIZE);
}

my $installed = 0;
unless ($installed) {

    my $fi = 0;
    while ( my $file = $config[ $fi * 2 ] ) {    # shift @config ) {
        my $fields = $config[ $fi * 2 + 1 ];

        my $ffi = 0;
        while ( my $field = $fields->[ $ffi * 2 ] ) {
            my $formatter = $fields->[ $ffi * 2 + 1 ];

            my $typei  = $fi;
            my $fieldi = $ffi;
            my $cb;

            if (USE_FORMATS) {
                $cb = sub {
                    $formatter->( $_[0]->[$typei]->[$fieldi] );
                };
            } else {
                $cb = sub {
                    $_[0]->[$typei]->[$fieldi];
                };
            }

            Sub::Install::install_sub(
                {
                    code => $cb,
                    into => __PACKAGE__,
                    as   => $field
                }
            );

            $ffi++;
        }

        $fi++;
    }

    $installed = 1;
}

sub _read {
    my $self = shift;
    my $file = shift;
    my $num  = shift;
    my $cb   = shift;

    my $buffer = '';
    my $pri    = aioreq_pri;
    my $grp    = aio_group $cb;
    limit $grp 1;
    $grp->result();

    add $grp aio_open $file, O_RDONLY, 0, sub {
        my $fh = shift or return;

        my $last_readsize = $rblk;
        feed $grp sub {
            if ( $last_readsize == $rblk ) {
                aioreq_pri $pri;
                add $grp aio_read $fh, length($buffer), $rblk, $buffer,
                  length($buffer), sub {
                    $last_readsize = $_[0];
                    if ( $last_readsize > 0 && $last_readsize < $rblk ) {
                        $self->[$num] = [ split( /\s+/, $buffer ) ];
                        $grp->result(1);
                    }
                  };
            }
        };
    };

    return $grp;
}

sub children {
    croak 'not loaded through ->tree' unless $_[0]->[2];

    return @{ $_[0]->[2] };
}

sub async_new {
    my $class = shift;
    my $cb    = pop;
    my $pid   = defined $_[0] ? shift : $$;

    my $self = bless [], $class;
    my $grp = aio_group $cb;
    $grp->result();

    my $cb_done = 0;
    my $i       = 0;
    while ( my $file = $config[ $i * 2 ] ) {
        my $fields = $config[ $i * 2 + 1 ];

        add $grp $self->_read(
            "/proc/$pid/$file",
            $i,
            sub {
                $cb_done++;

                if ( $cb_done == scalar(@config) / 2 ) {
                    $grp->result($self);
                }
            }
        );
        $i++;
    }

    $grp;
}

sub new {
    my $class = shift;
    my $pid   = shift;

    my $cv = AnyEvent->condvar;
    $class->async_new( $pid, $cv );

    return $cv->recv;
}

sub async_tree {
    my $class = shift;
    my $cb    = pop;
    my $pid   = shift;

    my @pi  = ();
    my $grp = aio_group sub {
        return $cb->() if ( @pi != scalar grep { defined } @pi );

        my %map = map { $_->[2] = []; $_->pid => $_ } @pi;

        my @top;
        foreach my $p ( sort { $a->pid <=> $b->pid } @pi ) {
            if ( $p->ppid ) {
                push @{ $map{ $p->ppid }->[2] }, $p;
            } else {
                push @top, $p;
            }
        }

        $cb->( defined $pid ? $map{$pid} : @top );
    };
    $grp->result();

    $grp->limit($max_fd/2);

    add $grp aio_readdirx "/proc", IO::AIO::READDIR_DENTS, sub {

        my @pids = ();
        foreach my $info ( @{ $_[0] } ) {
            next
              unless ( $info->[1] == IO::AIO::DT_DIR && $info->[0] =~ /^\d+$/ );
            push @pids, $info->[0];
        }

        feed $grp sub {
            my $cpid = shift @pids or return;

            add $grp $class->async_new(
                $cpid,
                sub {
                    push @pi, $_[0];
                }
            );
        };
    };

    $grp;
}

sub tree {
    my $class = shift;
    my $pid   = shift;

    my $cv = AnyEvent->condvar;
    $class->async_tree( $pid, $cv );

    return $cv->recv;
}

1;
