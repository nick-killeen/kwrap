# Run KWrap.

use warnings;
use strict;

use KWrap;

# Kwrap should become an absolute stats unit to help me decide from which pool I should be pulling ... thus I should keep a log of things internally.

sub evaluate {
	my ($kw, $command, @args) = @_;
		$kw // die; 

		my %aliases = (
			push     => sub {$kw->push(@_)},
			peek     => sub {$kw->peek(@_)},
			prime    => sub {$kw->prime(@_)},
			cycle    => sub {$kw->cycle(@_)},
			relax    => sub {$kw->relax(@_)},
			remove   => sub {$kw->remove(@_)},
			edit     => sub {$kw->edit(@_)},
			lookup   => sub {$kw->lookup(@_)},
		);
	
		# saving needs to be done only after slurping has succeeded, otherwise we don't have atomicity.

		$aliases{$command} //= sub {error => "'$command' is not a valid command."};
		return $aliases{$command}->(@args);
}

# usually
# > peek     -- What next?
# > cycle    -- I did that
# > peek     -- What next?
# > cycle    -- I did that
# > peek     -- What next? oh wait, goodnight
# > peek     -- What next again?
# > cycle    -- I did that, and i wrote logs separately in cal74
# > peek     -- What next?
# > prime    -- Myeh ... I don't want to do that right now, what next?
# > peek     -- What next?
# > prime    -- I forgot what I was meant to do, but want a fresh start. What next?
# > relax    -- Myeh ... I don't want to do that right now, or anything for that matter. let me relax. i want to live in ignorance for a while.


sub main {

	mkdir "data";
	my $kw = KWrap->new(
		path     => "data", 
		slurpTo  => sub { system "vim $_[0]"; },
		spewFrom => sub { system "vim -R $_[0]"; }
	);
	
	print "\$ ";
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		my %result = evaluate($kw, @tokens);
		
		# this has random order currently ... should fix.
		for (keys %result) {
			if ($_ eq "slurpHandle" or $_ eq "spewHandle") {
				$result{$_}->();
			} else {
				print "$_ $result{$_}\n";
			}
		}
		print "\$ ";
	}
}

main @ARGV;
