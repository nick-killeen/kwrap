# Run KWrap.

# This isn't really a shippable module ... cull h2xs directory structure wholly? it isn't needed?

use warnings;
use strict;

use KWrap;

sub main {
	mkdir "data";
	my $kw = KWrap->new("data");
	$kw->push({a => "ayy", b => "bee", c => "cee"}, 60);
	my %p = $kw->cycle();
	for (keys %p) {
		print "$_: $p{$_}\n";
	}
}

main @ARGV;