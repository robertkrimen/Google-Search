use inc::Module::Install;

name 'Google-Search';
all_from 'lib/Google/Search.pm';
readme_from 'lib/Google/Search.pm';

resources repository => 'http://github.com/robertkrimen/Google-Search';

parse_requires test => <<_END_;
Test::Most
_END_

parse_requires <<_END_;
Any::Moose
Carp::Clan::Share
JSON 2
LWP::UserAgent
Try::Tiny
URI
_END_

auto_install;

WriteAll;
