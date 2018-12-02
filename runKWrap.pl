# Run KWrap.

use warnings;
use strict;

use KWrap;

# This kwrap stores unstructured data, as at the removal of properties ... 


# evaluate :: token [args] -> [char]
sub evaluate {
	my ($kw, $command, @args) = @_;
		$kw // die; 

		# todo pithen
		my %aliases = (
			push   => sub {$kw->push(@_)},
			peek   => sub {$kw->peek(@_)},    # "um ... what was next again?"
			prime  => sub {$kw->prime(@_)},   # "what's next?" or "i don't like that but want to do something now, gimme!"
			cycle  => sub {$kw->cycle(@_)},   # "i just did that, and i wrote logs separately in cal74" 
			relax  => sub {$kw->relax(@_)},   # "i don't feel like doing that too soon ... i want to live in ignorance for a while, let me relax."
			remove => sub {$kw->remove(@_)},  # remove :: id -> void  ;  get :: id -> props ... 
			edit   => sub {$kw->edit(@_)},
			lookup => sub {$kw->lookup(@_)}
		);
	
		$aliases{$command} //= sub {{error => "'$command' is not a valid command."}};
		return $aliases{$command}->(@args);
		
		# $kw->save ... or should I save within KW? well ... If i save within KW, then i probably should be saving just withing K.
		# (then perform autosave) ... also, am i guaranteed atomicity in general when I edit files? is it already impossible at the OS level to corrupt INDIVIDUAL files w/ ctrl-C? 
		
		# elif delete { my ($actId) = @_)
		# elif edit @args (will interface as though the user is just pushing with properties of @args).
		# elif list all property_name # ??
		
		# "What's the difference between relaxing and priming, as opposed to just priming?" ...
}

# usually
# > peek     -- What next?
# > cycle    -- I did that
# > peek     -- What next?
# > cycle    -- I did that
# > peek     -- What next? oh wait, goodnight
# > peek     -- What next again?
# > cycle    -- I did that
# > peek     -- What next?
# > prime    -- Myeh ... I don't want to do that right now, what next?
# > peek     -- What next?
# > relax    -- Myeh ... I don't want to do that right now, or anything for that matter. let me relax.


# enforce unique bucket names

# I should have multiple buckets, no? 

sub main {
	# print @_; # @_ should contain bucket name

	mkdir "data";
	my $kw = KWrap->new("data");
	
	print "\$ ";
	while (<>) {
		chomp $_;
		
		return if $_ eq "";
		
		my @tokens = split(" ", $_);
		my %result = evaluate($kw, @tokens);
		$kw->save();
		print "$_: $result{$_}\n" for (keys %result);

		print "\$ "; # i shouldn't print this if terminating.
	}
}

# structure is required ... so a delimiter is needed.

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