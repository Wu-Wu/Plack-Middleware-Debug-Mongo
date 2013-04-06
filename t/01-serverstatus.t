use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeMongoDB;

t::lib::FakeMongoDB->run;

{
    use Plack::Middleware::Debug::Mongo::ServerStatus 'hashwalk';
    can_ok 'Plack::Middleware::Debug::Mongo::ServerStatus', qw/prepare_app run/;
    ok(defined &hashwalk, 'Mongo-ServerStatus: hashwalk imported');
}

# simple application
my $app = sub {[ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ]};

{
    $app = builder {
        enable 'Debug',
            panels => [
                [ 'Mongo::ServerStatus', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
            ];
        $app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200, 'Mongo-ServerStatus: response code 200';

        like $res->content,
            qr|<a href="#" title="Mongo::ServerStatus" class="plDebugServerStatus\d+Panel">|m,
            'Mongo-ServerStatus: panel found';

        like $res->content,
            qr|<small>Version: \d\.\d{1,2}\.\d{1,2}</small>|,
            'Mongo-ServerStatus: subtitle points to mongod version';

        like $res->content,
            qr|<td>uptime</td>[.\s\n\r]*<td>1738371</td>|m,
            'Mongo-ServerStatus: found uptime and its value';

        like $res->content,
            qr|<td>network.bytesOut</td>[.\s\n\r]*<td>9235789924</td>|m,
            'Mongo-ServerStatus: found network.bytesOut and its value';

        like $res->content,
            qr|<td>mem.bits</td>[.\s\n\r]*<td>64</td>|m,
            'Mongo-ServerStatus: found mem.bits and its value';

        like $res->content,
            qr|<td>mem.supported</td>[.\s\n\r]*<td>false</td>|m,
            'Mongo-ServerStatus: found mem.supported and its value (translated from boolean)';
    };
}

done_testing();
