package Slack::Base;
use Mojo::Base -base;

use Mojo::JSON;

use Mojo::UserAgent;
use SQL::Maker;
SQL::Maker->load_plugin('InsertMulti');

has 'c';
has 'dbh' => sub { shift->c->dbh };
has 'builder' => sub { SQL::Maker->new(driver => 'mysql') };
has 'ua' => sub {
    Mojo::UserAgent->new->max_redirects(5);
};
has 'config' => sub { shift->c->config };
has 'parser' => sub { Mojo::JSON->new };

sub _m { shift->c->_m(@_) };

1;
