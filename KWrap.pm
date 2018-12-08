# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;

# Public functions return hashes with some number of:
# error,
# actId,
# lifetime,
# spewHandle,
# slurpHandle

package KWrap {
	sub new {
		my ($class, %args) = @_;
		
		my $self = {
			path            => "KWrap",
			slurpTo         => sub { system "vim $_[0]" },    # :: path -> void (opens stdin port to path)
			spewFrom        => sub { system "vim -R $_[0]" }, # :: path -> void (opens stdout port to path)
			defaultLifetime => undef # undef will cause complaints if no lifetime is provided (unless recycle policy isn't fair)
		};

		my %karmaArgs = %args;
		delete $karmaArgs{$_} for (keys %$self);
		$self->{k} = Karma->new(%karmaArgs);
		
		# The Karma constructor will complain if it had recieved any invalid
		# arguments, so, at this point, we needn't question that %args make(s)
		# sense either to Karma or KWrap.
		$self->{$_} = $args{$_} for (keys %args);
		
		bless $self, $class;
	
		if (defined $self->{recycle} and ($self->{recycle} eq "eternal" or $self->{recycle} eq "destruct")) {
			$self->{defaultLifetime} //= 1;
		}
	
		if (-e "$self->{path}/Karma") {
			$self->{k}->load(path => "$self->{path}/Karma");
		} else {
			$self->_save();
		}
	
		mkdir "$self->{path}/acts";
		
		return $self;
	}
	
	sub _save {
		my ($self) = @_;
		
		$self->{k}->save(path => "$self->{path}/Karma");
	}
	
	sub _setAct {
		my ($self, $actId) = @_;
		
		return (
			actId       => $actId,
			lifetime    => $self->{k}->lifetime($actId),
			slurpHandle => sub { $self->{slurpTo}->("$self->{path}/acts/$actId"); $self->_save(); } # slurping and saving must be done at once to achieve atomicity and synchronicity of KW and K
		);
	}
	
	sub _getAct {
		my ($self, $actId) = @_;

		-e "$self->{path}/acts/$actId" or die "_getAct expects validity of actIDs, but was provided an actId that does not exist.";
		
		return (
			actId      => $actId,
			lifetime   => $self->{k}->lifetime($actId),
			spewHandle => sub { $self->{spewFrom}->("$self->{path}/acts/$actId") }
		);
	}

	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle() // return (error => "There are no acts in the cycle.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub edit {
		my ($self, $actId) = @_;
		$actId // return (error => "No actId provided to edit.");
		$actId =~ /^\d+$/ or return (error => "'$actId' is an invalid actId, cannot edit.");
		-e "$self->{path}/acts/$actId" or return (error => "Act $actId does not exist, cannot edit.");

		return $self->_setAct($actId);
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		$actId // return (error => "No actId provided to lookup.");
		$actId =~ /^\d+$/ or return (error => "'$actId' is an invalid actId, cannot lookup.");
		-e "$self->{path}/acts/$actId" or return (error => "Act $actId does not exist, cannot lookup.");
		
		return $self->_getAct($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek() // return (error => "There are no acts in the cycle.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime() // return (error => "There are no acts in the cycle.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub push {
		my ($self, $lifetime) = @_;
		$lifetime //= $self->{defaultLifetime};
		
		$lifetime // return (error => "No lifetime provided to push.");
		$lifetime =~ /^\d+$/ and $lifetime > 0 or return (error => "Invalid lifetime '$lifetime'.");
		
		opendir my $dh, "$self->{path}/acts";
		my @contents = readdir $dh;
		closedir $dh;
		my $actId = @contents - 2; # - 2 to ignore the directories '.' and '..'
		
		$self->{k}->push($actId, $lifetime);
	
		return $self->_setAct($actId);
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
		$self->_save();
		
		return ();
	}
	
	sub remove {
		my ($self, $actId) = @_;
		$actId // return (error => "No actId provided to remove.");
		$actId =~ /^\d+$/ or return (error => "'$actId' is an invalid actId, cannot remove.");
		-e "$self->{path}/acts/$actId" or return (error => "Act $actId does not exist, cannot remove.");
		
		$self->{k}->remove($actId) or return (error => "Act $actId has already been removed, cannot remove.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	# sub search :: (self * str) -> [actIds]  ... rather, return searchResults => (1, 2, 3) or does this flatten itself? in which case do searchResults => [1, 2, 3]
	
	# I want some type of searching functionality, so that I don't add duplicate words :|.
	# ((should only search non-deleted acts))). Wait ... should it search deleted acts? Sigh ... recycling policies hurt my brain.
	


	
	# TODO List:
	# - searching functionality.
	# - more unified searching functionality overall ... a _validator is probably the best way to go, but since we want it to return instead of dying, there will be a bit of overhead at each call.
	# - default slurping and spewing one liners, or gobble from STDIN, STDOUT?
	# - consolidate error messages into #defs (global constants, or constants of the package)\
	# - change error message "there are no acts in the cycle" -- I am confused when I type > cycle; and I get back < error => There are no acts in the cycle.

	# DONE list
	# - lookup .  or remove ./ ETC die rather than warning. The directories indeed exist; but these are not valid actIds!
	# - don't die on malformed
	#     - lifetime,  (X)
	#     - actId      (X)
	# - edit (X), push (X), remove (X), lookup (X) all warn and fail when no args are provided
	
}

1;

#sub new($class, %args)
#sub cycle($self)
#sub length($self)
#sub lifetime($self, $actId)
#sub load($self, %args)
#sub peek($self)
#sub prime($self)
#sub push($self, $actId, $lifetime)
#sub relax($self)
#sub remove($self, $actId)
#sub save($self, %args)

# it's a ridiculous thing to cycle without first priming if logging is going to be a part of the system.
# A: it depends on the scope of the system, and atomicity of cycling. For "here's something to think about", which is achieved at a glance, cycle-cycle-cycle is a valid use case.

