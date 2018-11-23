use warnings;
use strict;

package Act::SpecialAct {
	use parent 'Act::Act';

	sub amISpecial {
		print "yes!";
	}
}

1;