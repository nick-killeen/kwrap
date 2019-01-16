use warnings;
use strict;

use KWrap;

our $CONSOLE_INPUT_SYMBOL;
our $CONSOLE_OUTPUT_SYMBOL;
our $LOG_PATH;
our %COMMANDS;
our %KWRAP_ARGS;

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
	my ($alias, %filteredResult) = @_;
	
	my %displayedResult = %filteredResult;
	for (sort keys %filteredResult) {
		if ($_ eq "slurpHandle" or $_ eq "spewHandle") {
			# Run the callback functions, and replace the function handle with
			# its success code for logging purposes.
			$displayedResult{$_} = $filteredResult{$_}->($alias);
			# By passing the alias into the callback function, we can design 
			# KWrap's methods slurpTo and spewFrom to exhibit different
			# behaviour for different aliases.
		} elsif ($_ eq "matches") {
			print "${CONSOLE_OUTPUT_SYMBOL}$_\n" for (@{$filteredResult{$_}});
		} else {
			print "${CONSOLE_OUTPUT_SYMBOL}$_ $filteredResult{$_}\n";
		}
	}

	return %displayedResult;
}

sub logResult {
	my ($alias, $args, %displayedResult) = @_; 
	open my $fh, ">>", "$LOG_PATH" or die "Could not open log file '$LOG_PATH'";
	local $" = " ";
	print $fh "@" . time() . ":\n";
	print $fh "> $alias @$args\n";
	print $fh "< $_ => $displayedResult{$_}\n" for (sort keys %displayedResult);
	close $fh;
	return ();
}

sub parseArgs {
	my ($argStr, $nArgs) = @_;
	return () if ($nArgs == 0);
	return $argStr if ($nArgs == 1);
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
	my @args = parseArgs($argStr, $nArgs);
	my %result = $method->($kw, @args); 
	my %filteredResult = applyFilter($filter, %result);
	my %displayedResult = display($alias, %filteredResult);
	if ($bLog and not containsError(%displayedResult)) {
		logResult($alias, \@args, %displayedResult);
	}
}

sub resolveAlias {
	my ($alias) = @_;
	return $COMMANDS{$alias} // [sub {
		error => "'$alias' does not reference a valid command."
	}, 0, 0, [qw()]];
}



sub main {
	my ($configPath) = @_;
	$configPath //= "./config.pl";
	
	do $configPath or
		die "Configuration file '$configPath' failed to return non-zero code";
	
	my $kw = KWrap->new(%KWRAP_ARGS);
	
	print $CONSOLE_INPUT_SYMBOL;
	while (<STDIN>) {
		chomp $_;
		return if $_ eq "";

		evaluate($kw, $_);
		print $CONSOLE_INPUT_SYMBOL;
	}
}

main @ARGV;