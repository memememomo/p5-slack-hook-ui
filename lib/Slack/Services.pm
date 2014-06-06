package Slack::Services;
use Mojo::Base 'Slack::Base';

use Slack::Util;

sub fetch {
    my ($self, $service) = @_;

    my %map = (
        'bitbucket' => {
            name => 'Bitbucket',
        },
    );

    return $map{$service};
}

1;
