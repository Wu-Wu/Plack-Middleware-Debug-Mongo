use strict;
use Plack::Builder;

my $mongo_options = {
    host => 'mongodb://gib-in.zyxmasta.com:29111', # subject to change
};

builder {
    mount '/' => builder {
        enable 'Debug',
            panels => [
                [ 'Mongo::ServerStatus', connection => $mongo_options ],
            ];
        sub {
            [
                200,
                [ 'Content-Type' => 'text/html' ],
                [ '<html><body>OK</body></html>' ]
            ];
        };
    };
};
