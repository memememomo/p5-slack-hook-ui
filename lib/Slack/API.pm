package Slack::API;
use Mojo::Base -base;

use Mojo::UserAgent;

has 'ua' => sub {
    Mojo::UserAgent->new->max_redirects(5);
};


sub chat_post_message {
    my ($self, $args) = @_;

    my $tx = $self->ua->post('https://slack.com/api/chat.postMessage', form => $args);
    if (my $res, $tx->success) {
        return 1;
    }
    else {
        return 0;
    }
}


1;
