# Run KWrap.

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

# > peek
# < id:          XXX
# < name:        YYY
# < desc:        ZZZ
# < other_props: ...

# > prime
# < id:          XXX
# < name:        YYY
# < desc:        ZZZ
# < other_props: ...

# > cycle <logs>
# < id:          XXX
# < name:        YYY
# < desc:        ZZZ
# < other_props: ...