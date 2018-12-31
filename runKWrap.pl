use warnings;
use strict;

use KWrap;

sub evaluate {
	my ($kw, $command, @args) = @_;
		$kw // die; 

		my %aliases = (
			push   => sub {$kw->push(@_)},
			peek   => sub {$kw->peek(@_)},
			prime  => sub {$kw->prime(@_)},
			cycle  => sub {$kw->cycle(@_)},
			relax  => sub {$kw->relax(@_)},
			remove => sub {$kw->remove(@_)},
			edit   => sub {$kw->edit(@_)},
			lookup => sub {$kw->lookup(@_)},
			search => sub {$kw->search(@_)},
			tweak  => sub {$kw->tweakLifetime(@_)},
		);

		$aliases{$command} //= sub {error => "'$command' is not a valid command."};
		return $aliases{$command}->(@args);
}

sub display {
	my (%result) = @_;
	
	for (sort keys %result) {
		if ($_ eq "slurpHandle" or $_ eq "spewHandle") {
			$result{$_}->();
		} elsif ($_ eq "matches") {
			print "$_\n" for (@{$result{$_}});
		} else {
			print "$_ $result{$_}\n";
		}
	}
}

sub main {
	mkdir "data";
	my $kw = KWrap->new(
		path     => "data", 
		# slurpTo  => sub { system "vim $_[0]"; return -e $_[0] }, 
		# spewFrom => sub { system "vim -R $_[0]"; },
		defaultLifetime => 5
	);
	
	print "\$ ";
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		my %result = evaluate($kw, @tokens);
		display(%result);
		print "\$ ";
	}
}

main @ARGV;
