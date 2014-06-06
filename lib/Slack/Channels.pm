package Slack::Channels;

use Mojo::Base 'Slack::Base';


sub fetch_by_channel_id {
    my ($self, $channel_id) = @_;

    my ($sql, @binds) =
        $self->builder->select('channels', ['*'], {channel_id => $channel_id});

    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);

    my $channel = $sth->fetchrow_hashref;

    $sth->finish;

    return $channel;
}

sub list {
    my ($self) = @_;

    my ($sql, @binds) =
        $self->builder->select('channels', ['*']);

    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);

    my @list;
    while (my $h = $sth->fetchrow_hashref) {
        push @list, $h;
    }

    $sth->finish;

    return \@list;
}


sub sync {
    my ($self) = @_;

    my $url = 'https://slack.com/api/channels.list';
    my $tx = $self->ua->post($url, form => {
        token => $self->config->{Slack}->{api_token},
        exclude_archived => 1,
    });
    if (my $res = $tx->success) {
        my $hash = $res->json;
        $self->dbh->begin_work;
        $self->dbh->do("TRUNCATE channels");
        my @bulks;
        for my $channel (@{$hash->{channels}}) {
            push @bulks, {
                channel_id => $channel->{id},
                name => $channel->{name},
            };
        }
        my ($sql, @binds) = $self->builder->insert_multi('channels', \@bulks);
        my $sth = $self->dbh->prepare($sql);
        $sth->execute(@binds);
        $sth->finish;
        $self->dbh->commit;
    }
}


1;
