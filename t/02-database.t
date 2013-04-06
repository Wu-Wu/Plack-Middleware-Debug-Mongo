use strict;
use warnings;
use Plack::Test;
use Plack::Builder;
use HTTP::Request::Common;
use Test::More;
use t::lib::FakeMongoDB;

t::lib::FakeMongoDB->run;

{
    use Plack::Middleware::Debug::Mongo::Database;
    can_ok 'Plack::Middleware::Debug::Mongo::Database', qw/prepare_app run/;
}

# simple application
my $app = sub {[ 200, [ 'Content-Type' => 'text/html' ], [ '<html><body>OK</body></html>' ] ]};

{
    $app = builder {
        enable 'Debug',
            panels => [
                [ 'Mongo::Database', connection => { host => 'mongodb://localhost:27017', db_name => 'sampledb' } ],
            ];
        $app;
    };

    test_psgi $app, sub {
        my ($cb) = @_;

        my $res = $cb->(GET '/');
        is $res->code, 200, 'Mongo-Database: response code 200';

        like $res->content,
            qr|<a href="#" title="Mongo::Database" class="plDebugDatabase\d+Panel">|m,
            'Mongo-Database: panel found';

        like $res->content,
            qr|<small>sampledb</small>|,
            'Mongo-Database: subtitle points to sampledb';

        like $res->content,
            qr|<h3>Collection: models</h3>| &&
            qr|<td>avgObjSize</td>[.\s\n\r]*<td>1459.75</td>| &&
            qr|<td>count</td>[.\s\n\r]*<td>16</td>| &&
            qr|<td>indexSizes\._id_</td>[.\s\n\r]*<td>8176</td>| &&
            qr|<td>lastExtentSize</td>[.\s\n\r]*<td>24576</td>| &&
            qr|<td>ns</td>[.\s\n\r]*<td>sampledb.models</td>|,
            'Mongo-Database: has models collection statistics';

        like $res->content,
            qr|<h3>Collection: sessions</h3>| &&
            qr|<td>count</td>[.\s\n\r]*<td>363</td>| &&
            qr|<td>indexSizes\._id_</td>[.\s\n\r]*<td>24528</td>| &&
            qr|<td>ns</td>[.\s\n\r]*<td>sampledb.sessions</td>| &&
            qr|<td>numExtents</td>[.\s\n\r]*<td>3</td>| &&
            qr|<td>storageSize</td>[.\s\n\r]*<td>430080</td>|,
            'Mongo-Database: has sessions collection statistics';

        like $res->content,
            qr|<h3>Database: sampledb</h3>| &&
            qr|<td>avgObjSize</td>[.\s\n\r]*<td>643.318918918919</td>| &&
            qr|<td>collections</td>[.\s\n\r]*<td>8</td>| &&
            qr|<td>fileSize</td>[.\s\n\r]*<td>201326592</td>| &&
            qr|<td>nsSizeMB</td>[.\s\n\r]*<td>16</td>| &&
            qr|<td>objects</td>[.\s\n\r]*<td>740</td>|,
            'Mongo-Database: has sampledb statistics';
    };
}

done_testing();
