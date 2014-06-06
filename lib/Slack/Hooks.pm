package Slack::Hooks;
use Mojo::Base 'Slack::Base';

use Slack::Util;

use Encode;

has 'API' => sub { shift->_m('Slack::API') };
has 'Services' => sub { shift->_m('Slack::Services') };
has 'Channels' => sub { shift->_m('Slack::Channels') };


sub endpoint {
    my ($self, $hook) = @_;
    my $token = $hook->{token};
    my $service = $hook->{service};
    return $self->c->url_with('/services/hooks/'.$service)->query(token => $token)->to_abs;
}

sub fetch_by_token {
    my ($self, $token) = @_;

    my ($sql, @binds) = $self->builder->select('hooks', ['*'], {token => $token});
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);

    my $hook = $sth->fetchrow_hashref;

    $sth->finish;

    return $hook;
}

sub fetch {
    my ($self, $id) = @_;

    my ($sql, @binds) = $self->builder->select('hooks', ['*'], {id => $id});
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);

    my $hook = $sth->fetchrow_hashref;
    $hook->{botname} ||= $hook->{service};
    $hook->{endpoint} = $self->endpoint($hook);

    $sth->finish;

    return $hook;
}

sub update {
    my ($self, $v, $id) = @_;

    my %values = (
        channel_id => $v->{channel_id},
        label      => $v->{label},
        botname    => $v->{botname},
        updated_at => \'NOW()',
    );
    my ($sql, @binds) = $self->builder->update('hooks', \%values, {id => $id});
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    $sth->finish;

    return $id;
}

sub create {
    my ($self, $v) = @_;

    my %values = (
        service => $v->{service},
        channel_id => $v->{channel_id},
        token => Slack::Util::generate_id(10),
        created_at => \'NOW()',
        updated_at => \'NOW()',
    );

    my ($sql, @binds) = $self->builder->insert('hooks', \%values);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute(@binds);
    $sth->finish;

    return $self->dbh->{mysql_insert_id};
}

sub list_group_by_service {
    my ($self) = @_;

    my ($sql, @binds) = $self->builder->select('hooks', ['*']);
    my $sth = $self->dbh->prepare($sql);
    $sth->execute();

    my %services;
    while (my $h = $sth->fetchrow_hashref) {
        my $service = $h->{service};
        $h->{botname} ||= $service;
        $h->{channel} = $self->Channels->fetch_by_channel_id($h->{channel_id});
        $services{$service} ||= [];
        push @{$services{$service}}, $h;
    }
    $sth->finish;

    my @list;
    for my $service (keys %services) {
        my $s = $self->Services->fetch($service);
        push @list, {
            service => $s,
            hooks => $services{$service},
        };
    }

    return \@list;
}

sub dispatch {
    my ($self, $service, $req) = @_;

    my $module = 'Slack::Services::'.ucfirst($service);
    my $m = $self->_m($module);

    return $m->run($req);
}

1;
