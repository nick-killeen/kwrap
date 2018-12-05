# Run KWrap.

use warnings;
use strict;

use KWrap;

# This kwrap stores unstructured data, as at the removal of properties ... 

# Kwrap should become an absolute stats unit to help me decide from which pool I should be pulling ... thus I should keep a log of things internally.


# evaluate :: token [args] -> [char]
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
			lookup => sub {$kw->lookup(@_)}
		);
	
		$kw->save();
		$aliases{$command} //= sub {errorMessage => "'$command' is not a valid command."};
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
	
	print "\$ "; # I want to keep printing this, no?
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		my %result = evaluate($kw, @tokens);
		print $result{errorMessage} if (defined $result{errorMessage})
	}
}

main @ARGV;
