use warnings;
use strict;

use KWrap;

sub concatInto {
	my ($handle) = @_;
	
	return sub {
		my ($kw, @args) = @_;
		my $argsConcat = join(" ", @args);
		return $handle->($kw, $argsConcat);
	
	};
}

sub resolveAlias {
	my ($alias) = @_;
	my %commands = (
		# alias => [method, bLog, filters],
		cycle  => [\&KWrap::cycle,         1, [qw()]],
		edit   => [\&KWrap::edit,          0, [qw(actId lifetime)]],
		lookup => [\&KWrap::lookup,        0, [qw(actId)]],
		peek   => [\&KWrap::peek,          0, [qw()]],
		prime  => [\&KWrap::prime,         0, [qw()]],
		push   => [\&KWrap::push,          1, [qw(lifetime)]],
		relax  => [\&KWrap::relax,         0, [qw()]],
		remove => [\&KWrap::remove,        1, [qw(actId lifetime spewHandle)]],
		search => [concatInto(\&KWrap::search),
		                                   0, [qw()]],
		tweak  => [\&KWrap::tweakLifetime, 1, [qw()]],
	);
	return $commands{$alias} // [sub {
		error => "'$alias' does not reference a valid command."
	}, 0, [qw()]];
}

sub evaluate {
	my ($kw, $alias, @args) = @_;
	$kw // die; 
	
	# Resolve the the alias to get an executable command (plus logging and
	# filtering information).
	my $command = resolveAlias($alias);
	my ($method, $bLog, $filters) = @$command;

	# Run the command.
	my %result = $method->($kw, @args);
	
	# Apply filters.
	delete $result{$_} for (@$filters);
	
	# Print the result to the console, additionally running callback functions
	# to allow the reading and writing of acts.
	for (sort keys %result) {
		if ($_ eq "slurpHandle" or $_ eq "spewHandle") {
			# Run the callback functions, and replace the function handle with
			# its success code for logging purposes.
			$result{$_} = $result{$_}->();
		} elsif ($_ eq "matches") {
			print "$_\n" for (@{$result{$_}});
		} else {
			print "$_ $result{$_}\n";
		}
	}

	# Log the input and output (if there weren't any errors).
	if ($bLog and not defined $result{error}) {
		open my $fh, ">>", "data/log";
		local $" = " ";
		print $fh "> $alias @args\n";
		print $fh "< $_ => $result{$_}\n" for (sort keys %result);
		close $fh;
	}
}


sub main {
	mkdir "data";
	my $kw = KWrap->new(
		path     => "data", 
		# slurpTo  => sub { system "vim $_[0]"; return -e $_[0] }, 
		# spewFrom => sub { system "vim -R $_[0]"; return 1},
		defaultLifetime => 5
	);
	
	print "\$ ";
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		evaluate($kw, @tokens);
		print "\$ ";
	}
}

main @ARGV;
