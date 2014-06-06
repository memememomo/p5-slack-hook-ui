package Slack::Services::Bitbucket;
use Mojo::Base 'Slack::Base';

use Encode;

has 'Hooks' => sub { shift->_m('Slack::Hooks') };
has 'API' => sub { shift->_m('Slack::API') };

sub run {
    my ($self, $req) = @_;

    my $payload = $req->{payload};
    my $hash = $self->parser->decode(encode_utf8($payload));

    my $canon_url = $hash->{canon_url};
    my $base_url = $hash->{repository}->{absolute_url};
    my $repos_name = $hash->{repository}->{name};
    my $commits = $hash->{commits};
    my $commits_num = @$commits;

    my @messages;
    for my $commit (@$commits) {
        my $author = $commit->{author};
        my $branch = $commit->{branch};
        my $message = $commit->{message};
        my $raw_node = $commit->{raw_node};
        my $node = $commit->{node};
        push @messages, "[$repos_name/$branch] <${canon_url}${base_url}commits/$raw_node|$node> $message - $author";
    }

    my $token = $req->{token};
    my $hook = $self->Hooks->fetch_by_token($token);
    my $botname = $hook->{botname};
    my $channel_id = $hook->{channel_id};

    my %args = (
        token => $self->c->config->{Slack}->{api_token},
        channel => $channel_id,
        text => join("\n", @messages),
        username => $botname,
        icon_url => $self->c->url_for('/img/bitbucket_48.png')->to_abs,
    );

    return $self->API->chat_post_message(\%args);
}

1;
