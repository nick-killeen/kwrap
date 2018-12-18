# Autotests for KWrap.

use warnings;
use strict;

use Try::Tiny;
use File::Path 'rmtree';

use KWrap;

# This directory will be clobbered.
my $TEST_DIRECTORY = "test23912320102";


sub testSlurpTo {
	$_[2] != 0 or return 0;
	open my $fh, ">", $_[0];
	print $fh $_[1];
	close $fh;
	return 1;
}
sub testSpewFrom {
	open my $fh, "<", $_[0];
	my $toSpew = do { local $/ = undef; <$fh> };
	close $fh;
	return $toSpew;
}

sub testKWrap {
	rmtree $TEST_DIRECTORY;
	mkdir $TEST_DIRECTORY;
	my $kw = KWrap->new(
		path => $TEST_DIRECTORY,
		slurpTo  => \&testSlurpTo,
		spewFrom => \&testSpewFrom
	);
	
	my %o; # enforce lineraity
	
	# Test peek, prime, and cycling an empty karma yeilds no results.
	{
		%o = $kw->peek();
		$o{error} eq $KWrap::CODE::PEEK_ON_EMPTY or die;
		
		%o = $kw->prime();
		$o{error} eq $KWrap::CODE::PRIME_ON_EMPTY or die;
		
		%o = $kw->cycle();
		$o{error} eq $KWrap::CODE::CYCLE_ON_EMPTY or die;
	}
	
	
	# Test edit, lookup, and remove all gracefully fail in when karma is empty.
	{
		%o = $kw->edit(0);
		$o{error} eq $KWrap::CODE::EDIT_BAD_ID or die;
		
		%o = $kw->lookup(0);
		$o{error} eq $KWrap::CODE::LOOKUP_BAD_ID or die;
		
		%o = $kw->remove(0);
		$o{error} eq $KWrap::CODE::REMOVE_BAD_ID or die;
	}
	
	# Test edit, lookup, and remove all fail when fed malformed IDs.
	{
		%o = $kw->edit(-1);
		$o{error} eq $KWrap::CODE::EDIT_BAD_ID or die;
		
		%o = $kw->lookup('.');
		$o{error} eq $KWrap::CODE::LOOKUP_BAD_ID or die;
		
		%o = $kw->remove(undef);
		$o{error} eq $KWrap::CODE::REMOVE_BAD_ID or die;
	}
	
	# Test pushing with bad lifetimes.
	{
		%o = $kw->push('bad');
		$o{error} eq $KWrap::CODE::PUSH_BAD_LIFETIME or die;
		%o = $kw->push(-5);
		$o{error} eq $KWrap::CODE::PUSH_BAD_LIFETIME or die;
		%o = $kw->push(undef);
		$o{error} eq $KWrap::CODE::PUSH_BAD_LIFETIME or die;
	}
	
	# Test successful push and lookup.
	{
		%o = $kw->push(2);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 2 or die;
		$o{slurpHandle}->("One two three four five six\n", 1) or die;
		
		%o = $kw->lookup(0);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 2 or die;
		$o{spewHandle}->() eq "One two three four five six\n" or die;
	}
	
	# Test cylcing reduces lifetime.
	{
		%o = $kw->cycle();
		$o{actId} eq 0 or die;
		$o{lifetime} eq 1 or die;
		$o{spewHandle}->() eq "One two three four five six\n" or die; 
		
		%o = $kw->lookup(0);
		$o{lifetime} eq 1 or die;
	}
	
	# Test editing.
	{
		%o = $kw->edit(0);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 1 or die;
		$o{slurpHandle}->("One two three four\n", 1) or die;
		
		%o = $kw->lookup(0);
		$o{spewHandle}->() eq "One two three four\n" or die;
	}
		
	# Test removing sets lifetime to 0, does not prevent edits and lookups, but disallows duplicate removals, and causes the act to no longer be in the karma cycle.
	{
		%o = $kw->peek();
		$o{actId} eq 0 or die;
		
		%o = $kw->remove(0);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 0 or die;
		$o{spewHandle}->() eq "One two three four\n" or die;
		
		%o = $kw->edit(0);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 0 or die;
		$o{slurpHandle}->("123456\n", 1) or die;
		
		%o = $kw->lookup(0);
		$o{actId} eq 0 or die;
		$o{lifetime} eq 0 or die;
		$o{spewHandle}->() eq "123456\n" or die;
		
		%o = $kw->peek();
		$o{error} eq $KWrap::CODE::PEEK_ON_EMPTY or die;
		
		%o = $kw->remove(0); 
		$o{error} eq $KWrap::CODE::REMOVE_ALREADY_REMOVED or die;
	}
	
	# Test the defaultLifetime constructor argument.
	{
		my $kw = KWrap->new(
			defaultLifetime => 5,
			path => $TEST_DIRECTORY,
			slurpTo  => \&testSlurpTo,
			spewFrom => \&testSpewFrom
		);
	
		%o = $kw->push();
		$o{actId} eq 1 or die;
		$o{lifetime} eq 5 or die;
		$o{slurpHandle}->("A1", 1) or die;
	}
	
	# Test recycle => "eternal" | "destruct" provide a default defaultLifetime of 1, and that these constructor arguments trickle down to Karma.
	{
		my $kw = KWrap->new(
			path => $TEST_DIRECTORY,
			recycle => "eternal",
			slurpTo  => \&testSlurpTo,
			spewFrom => \&testSpewFrom
		);
		
		%o = $kw->push();
		$o{actId} eq 2 or die;
		$o{lifetime} eq 1 or die;
		$o{slurpHandle}->("A2", 1) or die;

		$kw->remove(2); 
		
		%o = $kw->cycle();
		$o{lifetime} eq 5 or die;
		
		$kw = KWrap->new(
			path => $TEST_DIRECTORY,
			recycle => "destruct",
			slurpTo  => \&testSlurpTo,
			spewFrom => \&testSpewFrom
		);
		
		%o = $kw->cycle();
		$o{lifetime} eq 0 or die;
		
		%o = $kw->push();
		$o{actId} eq 3 or die;
		$o{lifetime} eq 1 or die;
		$o{slurpHandle}->("A3", 1) or die;
		
	}
	
	# Test that not slurping or returning a 0 code from a slurp will cause no changes to the system state.
	{
		%o = $kw->push(5);
		$o{actId} eq 4 or die;
		
		%o = $kw->lookup(4);
		$o{error} eq $KWrap::CODE::LOOKUP_BAD_ID or die;

		%o = $kw->push(5);
		$o{actId} eq 4 or die;
		$o{slurpHandle}->("don't commit", 0) == 0 or die;
		
		%o = $kw->remove(3);
		
		%o = $kw->peek();
		$o{error} eq $KWrap::CODE::PEEK_ON_EMPTY or die;
	}
	
	# Test searching.
	{
		%o = $kw->search(undef);
		shift @{$o{matches}} == 0 or die;
		shift @{$o{matches}} == 1 or die;
		shift @{$o{matches}} == 2 or die;
		shift @{$o{matches}} == 3 or die;
		not defined shift @{$o{matches}} or die;
		
		
		%o = $kw->search("");
		shift @{$o{matches}} == 0 or die;
		shift @{$o{matches}} == 1 or die;
		shift @{$o{matches}} == 2 or die;
		shift @{$o{matches}} == 3 or die;
		not defined shift @{$o{matches}} or die;
		
		%o = $kw->search("A");
		shift @{$o{matches}} == 1 or die;
		shift @{$o{matches}} == 2 or die;
		shift @{$o{matches}} == 3 or die;
		not defined shift @{$o{matches}} or die;
		
		%o = $kw->search("a"); # test for non-case sensitivity
		shift @{$o{matches}} == 1 or die;
		shift @{$o{matches}} == 2 or die;
		shift @{$o{matches}} == 3 or die;
		not defined shift @{$o{matches}} or die;
		
		%o = $kw->search("2");
		shift @{$o{matches}} == 0 or die;
		shift @{$o{matches}} == 2 or die;
		not defined shift @{$o{matches}} or die;

		%o = $kw->search("123456\n");
		shift @{$o{matches}} == 0 or die;
		not defined shift @{$o{matches}} or die;

		%o = $kw->search("123456\n1234");
		not defined shift @{$o{matches}} or die;
		
	}
	
	rmtree $TEST_DIRECTORY;
	print "All tests passed!";
}

testKWrap @ARGV;

