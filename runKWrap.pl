use warnings;
use strict;

use KWrap;

my $CONSOLE_INPUT_SYMBOL = "\$ ";
my $CONSOLE_OUTPUT_SYMBOL = "| ";
my $KWRAP_PATH = "data";

sub applyFilter {
	my ($filter, %result) = @_;
	my %filteredResult = %result;
	delete $filteredResult{$_} for (@$filter);
	return %filteredResult;
}

sub containsError {
	my (%displayedResult) = @_;
	my $bError = defined $displayedResult{error};
	return $bError;
}

sub display {
	my (%filteredResult) = @_;
	
	my %displayedResult = %filteredResult;
	for (sort keys %filteredResult) {
		if ($_ eq "slurpHandle" or $_ eq "spewHandle") {
			# Run the callback functions, and replace the function handle with
			# its success code for logging purposes.
			$displayedResult{$_} = $filteredResult{$_}->();
		} elsif ($_ eq "matches") {
			print "${CONSOLE_OUTPUT_SYMBOL}$_\n" for (@{$filteredResult{$_}});
		} else {
			print "${CONSOLE_OUTPUT_SYMBOL}$_ $filteredResult{$_}\n";
		}
	}

	return %displayedResult;
}

sub logResult {
	my ($commandStr, %displayedResult) = @_; 
	open my $fh, ">>", "$KWRAP_PATH/log";
	local $" = " ";
	print $fh "> $commandStr\n";
	print $fh "< $_ => $displayedResult{$_}\n" for (sort keys %displayedResult);
	close $fh;
	return ();
}

sub parseArgs {
	my ($argStr, $nArgs) = @_;
	return "" if ($nArgs < 0); # TODO "cycle 1 2 3 4" is equivalent to "cycle", but gets logged as "cycle 1 2 3 4" ... nArgs is off by 1
	return $argStr if ($nArgs == 0);
	my ($arg, $argStrRest) = $argStr =~ /^([^ ]*) *(.*)$/;
	my @args = ($arg, parseArgs($argStrRest, $nArgs - 1));
	return @args;
}

sub parseCommand {
	my ($commandStr) = @_;
	my ($command, $argStr) = $commandStr =~ /^([^ ]*) *(.*)$/;
	return ($command, $argStr);
}

sub evaluate {
	my ($kw, $commandStr) = @_;
	
	my ($alias, $argStr) = parseCommand($commandStr);
	my $command = resolveAlias($alias);
	my ($method, $nArgs, $bLog, $filter) = @$command;
	my @args = parseArgs($argStr, $nArgs - 1); # TODO HACK -1
	my %result = $method->($kw, @args); 
	my %filteredResult = applyFilter($filter, %result);
	my %displayedResult = display(%filteredResult);
	if ($bLog and not containsError(%displayedResult)) {
		logResult($commandStr, %displayedResult);
	}
}

sub resolveAlias {
	my ($alias) = @_;
	my %commands = (
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
	return $commands{$alias} // [sub {
		error => "'$alias' does not reference a valid command."
	}, 0, 0, [qw()]];
}



sub main {
	our $CONSOLE_INPUT_SYMBOL  = shift @_ // $CONSOLE_INPUT_SYMBOL;
	our $CONSOLE_OUTPUT_SYMBOL = shift @_ // $CONSOLE_OUTPUT_SYMBOL;
	our $KWRAP_PATH            = shift @_ // $KWRAP_PATH;

	mkdir $KWRAP_PATH;
	my $kw = KWrap->new(
		path     => $KWRAP_PATH, 
		# slurpTo  => sub { system "vim $_[0]"; return -e $_[0] }, 
		# spewFrom => sub { system "vim -R $_[0]"; return 1},
		defaultLifetime => 5
	);
	
	print $CONSOLE_INPUT_SYMBOL;
	while (<STDIN>) {
		chomp $_;
		return if $_ eq "";

		evaluate($kw, $_);
		print $CONSOLE_INPUT_SYMBOL;
	}
}

main @ARGV;