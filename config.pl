use warnings;
use strict;

our $CONSOLE_INPUT_SYMBOL = "\$ ";
our $CONSOLE_OUTPUT_SYMBOL = "| ";
our $LOG_PATH = "KWrap/log";

our %KWRAP_ARGS = (
	path => "KWrap",
	slurpTo  => sub { system "vim $_[0]"; return -e $_[0] }, 
	spewFrom => sub { system "vim -R $_[0]"; return 1},	
	defaultLifetime => 2,
);

1;