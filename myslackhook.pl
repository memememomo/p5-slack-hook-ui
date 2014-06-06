use Mojolicious::Lite;
use DBI;
use Mojo::Loader;
use lib 'lib';

# Charset
app->plugin('charset' => {charset => 'UTF-8'});

# Load config
app->plugin(config => {
    file      => app->home->rel_file('/config.pl'),
    stash_key => 'config',
});

# DB
app->helper(dbh => sub {
    my $c = shift;
    $c->{___slack_db} ||= do {
        my $dbi_config = $ENV{'CONFIG_DBI'} || $c->config->{'DBI'};
        DBI->connect(@$dbi_config);
    };
    return $c->{___slack_db};
});

# エラーメッセージの設定
app->helper(set_error_messages => sub {
    my ($self, $messages) = @_;
    if (! ref $messages) {
        $messages = [$messages];
    }
    $self->stash(error_messages => $messages);
});

# リダイレクト後のメッセージを設定
app->helper(set_result_message => sub {
    my ($self, $result_message) = @_;
    $self->flash(result_message => $result_message);
});

# Modelロード
app->helper(_m => sub {
    my $c = shift;
    my $name = shift;

    my $module_name = $name;

    my $e = Mojo::Loader->new->load($module_name);
    if ($e) {
        die "failed to load: $module_name: $@";
    }

    my $m = $module_name->new(
        c => $c,
        @_,
    );

    return $m;
});

app->helper(is_get_method => sub {
    my $self = shift;
    return lc($self->req->method) eq 'get';
});

app->helper(is_post_method => sub {
    my $self = shift;
    return lc($self->req->method) eq 'post';
});

app->helper(req_to_hash => sub {
    my $self = shift;
    return $self->req->params->to_hash()
});

app->helper(nl2br => sub {
    my ($c, $text) = @_;
    $text =~ s/(\r\n|\n\r|\n|\r)/<br\/>$1/g;
    return $text;
});

# Template Engine
app->plugin('xslate_renderer' => {
    template_options => { syntax => 'TTerse' },
});

app->plugin('FillInFormLite');



app->helper('Services' => sub { shift->_m('Slack::Services') });
app->helper('Hooks' => sub { shift->_m('Slack::Hooks') });
app->helper('Channels' => sub { shift->_m('Slack::Channels') });

any '/admin/sync' => sub {
    my $self = shift;

    if ($self->is_post_method) {
        $self->Channels->sync;
        return $self->redirect_to('admin/sync');
    }

    $self->render();
} => 'admin/sync';

any '/' => sub {
    my $self = shift;
    $self->redirect_to('services/index');
} => 'index';


any '/services' => sub {
    my $self = shift;
    $self->stash->{list} = $self->Hooks->list_group_by_service();
    $self->render();
} => 'services/index';

any '/services/new' => sub {
    my $self = shift;
    $self->render();
} => 'services/new';

any '/services/new/:service' => sub {
    my $self = shift;

    $self->stash->{channels} = $self->Channels->list();

    if ($self->is_post_method) {
        my $id;
        eval {
            my $v = $self->req_to_hash;
            $v->{service} = $self->param('service');
            $id = $self->Hooks->create($v);
        };
        if ($@) {
            $self->set_error_messages($@);
            return $self->render_fillinform($self->req_to_hash);
        }
        $self->set_result_message('作成しました。');
        return $self->redirect_to('services/update', {id => $id});
    }

    $self->render();
} => 'services/new/form';

post '/services/hooks/:service' => sub {
    my $self = shift;

    my $service = $self->param('service');
    my $req = $self->req_to_hash;

    $self->Hooks->dispatch($service, $req);

    $self->render(text => 'ok');
} => 'hooks/service';

any '/services/:id' => sub {
    my $self = shift;

    my $id = $self->param('id');

    $self->stash->{channels} = $self->Channels->list();
    $self->stash->{hook} = $self->Hooks->fetch($id);

    if ($self->is_post_method) {
        eval {
            $id = $self->Hooks->update($self->req_to_hash, $id);
        };
        if ($@) {
            $self->set_error_message($@);
            return $self->render_fillinform($self->req_to_hash);
        }
        $self->set_result_message('更新しました。');
        return $self->redirect_to('services/update', {id => $id});
    }

    my $filled = $self->Hooks->fetch($self->param('id'));
    $self->render_fillinform($filled);
} => 'services/update';

app->start;
