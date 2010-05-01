use inc::Module::Install;

name 'Google-Search';
all_from 'lib/Google/Search.pm';
readme_from 'lib/Google/Search.pm';

resources repository => 'http://github.com/robertkrimen/google-search/tree/master';

{
    require ExtUtils::MakeMaker;
    use strict;
    no strict 'refs';

    my $libscan = \&{"ExtUtils::MM_Any::libscan"};
    *{"ExtUtils::MM_Any::libscan"} = sub {
        return '' unless $libscan->(@_);
        return '' if $_[1] =~ /\.sw[p-z]$/;
        return $_[1];
    };
}

{
    map { my ($pk, $vr) = split m/\s/; build_requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Test::Most
_END_

    map { my ($pk, $vr) = split m/\s/; requires $pk => $vr || 0 } grep { ! /^\s*#/ } split m/\n/, <<_END_;
Any::Moose
Carp::Clan::Share
JSON 2
LWP::UserAgent
Try::Tiny
URI
_END_
}

auto_install;

WriteAll;
