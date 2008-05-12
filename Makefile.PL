use inc::Module::Install;

name 'Google-Search';
all_from 'lib/Google/Search.pm';

build_requires 'Test::More';

for (split m/\n/, <<_END_) {
Carp::Clan::Share
JSON 2
LWP::UserAgent
Moose
URI
_END_
    my ($module, $version) = split m/\s+/, $_;
    requires $module, $version;
}

auto_install;

WriteAll;

