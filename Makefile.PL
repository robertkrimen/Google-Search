use inc::Module::Install;

name 'Google-Search';
all_from 'lib/Google/Search.pm';

build_requires 'Test::More';

auto_install;

WriteAll;

