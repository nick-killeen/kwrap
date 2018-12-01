# Run KWrap.

use warnings;
use strict;

use KWrap;


# evaluate :: token [args] -> [char]
sub evaluate {
	my ($kw, $command, @args) = @_;
		$kw // die; 
		
		my $result;
		if ($command eq "push") {
			$result = $kw->push(@args); # last arg is lifetime
			#$result = $kw->push(@args); # pushing will eventually certainly be more complicated than this ... maybe prompt for further user input? maybe say "push name desc XXX" and we can prompt thrice for name, desc, and XXX?
			                            # maybe, on prompting, give the option to say "from C:/users/nicho/..." and it will mv the file into the act prop subdir?
		} elsif ($command eq "peek") {
			$result = $kw->peek();              # "Um ... what was next again?"
		} elsif ($command eq "prime") {
			$result = $kw->prime();             # "What's next?" or "I don't like that but want to do something now, gimme!"
		} elsif ($command eq "cycle") {
			$result = $kw->cycle();	            # "I just did that, and I wrote logs separately in Cal74" 
		} elsif ($command eq "relax") {
			$result = $kw->relax();             # "I don't feel like doing that too soon ... I want to live in ignorance for a while, let me relax."
		} else {
			die "$command is not a command";    # death is too harsh
		}
		
		return $result; # results should be a string!
		
		# $kw->save ... or should I save within KW? well ... If i save within KW, then i probably should be saving just withing K.
		# (then perform autosave) ... also, am i guaranteed atomicity in general when I edit files? is it already impossible at the OS level to corrupt INDIVIDUAL files w/ ctrl-C? 
		
		# elif delete { my ($actId) = @_)
		# elif edit @args (will interface as though the user is just pushing with properties of @args).
		# elif list all property_name # ??
		
		# "What's the difference between relaxing and priming, as opposed to just priming?" ...
}

# enforce unique bucket names


# no bucket names for now ... XP

sub main {
	# print @_;

	mkdir "data";
	my $kw = KWrap->new("data");
	
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		my $result = evaluate($kw, @tokens);
		$kw->save(); # where exactly to save? idk, try to match it up with the other file writes.
		print "$_: $result->{$_}\n" for (keys %$result) #    (in most cases)
		#

		
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

# > cycle
# < done, you just cycled name-id-desc-other props. don't forget to write logs manually in calendar.