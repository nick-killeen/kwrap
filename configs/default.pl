use warnings;
use strict;

our $CONSOLE_INPUT_SYMBOL = "\$ ";
our $CONSOLE_OUTPUT_SYMBOL = "| ";
our $LOG_PATH = "KWrap/log";

our %COMMANDS = (
	# alias => [method, nArgs, bLog, filters],
	cycle  => [\&KWrap::cycle,         0, 1, [qw()]],
	edit   => [\&KWrap::edit,          1, 0, [qw(actId lifetime)]],
	lookup => [\&KWrap::lookup,        1, 0, [qw(actId)]],
	peek   => [\&KWrap::peek,          0, 0, [qw()]],
	prime  => [\&KWrap::prime,         0, 0, [qw()]],
	push   => [\&KWrap::push,          1, 1, [qw(lifetime)]],
	relax  => [\&KWrap::relax,         0, 0, [qw()]],
	remove => [\&KWrap::remove,        1, 1, [qw(actId lifetime spewHandle)]],
	search => [\&KWrap::search,        1, 0, [qw()]],
	tweak  => [\&KWrap::tweakLifetime, 2, 1, [qw()]],
);

our %KWRAP_ARGS = (
	path => "KWrap",
	slurpTo  => sub { system "vim $_[0]"; return -e $_[0] }, 
	spewFrom => sub { system "vim -R $_[0]"; return 1},	
	defaultLifetime => 2,
);

1;