package Slack::Util;

use strict;
use warnings;
use utf8;
use Digest::SHA1 ();
use Time::HiRes ();

sub generate_id {
    my ($sid_length) = @_;
    $sid_length ||= 100000;
    my $unique = ( [] . rand() );
    return substr( Digest::SHA1::sha1_hex( Time::HiRes::gettimeofday() . $unique ), 0, $sid_length);
}

1;
