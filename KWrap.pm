# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;

# Public functions return hashes with some number of:
# errorMessage,
# actId,
# lifetime,
# spewHandle,
# slurpHandle

package KWrap {
	sub new {
		my ($class, %args) = @_;
		
		# there must be no naming collisions with Karma
		# TODO, handle eternal 5 5 5 5 5 5 5 5 5 5 5 lifetime
		my $self = {
			path            => "KWrap",
			slurpTo         => sub { system "vim $_[0]" },   # :: path -> void (opens stdin port)
			spewFrom        => sub { system "vim -R $_[0]" }, # :: path -> void (opens stdout port)
			defaultLifetime => undef, # undef will cause complaints if no lifetime is provided (unless recycle policy is unfair)
		};

		my %karmaArgs = %args;
		delete $karmaArgs{$_} for (keys %$self);
		$self->{k} = Karma->new(%karmaArgs);
		
		# The Karma constructor will complain if it had recieved any invalid
		# arguments, so, at this point, we needn't question that %args make(s)
		# sense either to Karma or KWrap.
		$self->{$_} = $args{$_} for (keys %args);
		
		bless $self, $class;
	
		if ($self->{recycle} eq "eternal" or $self->{recycle} eq "destruct") {
			$self->{defaultLifetime} //= 1;
		}
	
		if (-e "$self->{path}/Karma") {
			$self->{k}->load(path => "$self->{path}/Karma");
		} else {
			$self->{k}->_save();
		}
	
		mkdir "$self->{path}/acts";
		
		return $self;
	}
	
	# this currently trusts the veracity of IDs ... feel free to die otherwise.
	sub _getAct {
		my ($self, $actId) = @_;
		
		return (
			actId      => $actId,
			lifetime   => $self->{k}->lifetime($actId),
			spewHandle => sub { $self->{spewFrom}->("$self->{path}/acts/$actId") }
		);
		
	}
	
	sub _setAct {
		my ($self, $actId) = @_;
		
		return (
			actId      => $actId,
			lifetime   => $self->{k}->lifetime($actId),
			slurpHandle => sub { $self->{slurpTo}->("$self->{path}/acts/$actId"); $self->_save(); } # slurping and saving must be done at once to achieve atomicity and synchronicity of KW and K
		);
	}
	
	sub _save {
		my ($self) = @_;
		
		$self->{k}->save(path => "$self->{path}/Karma");
	}
	
	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle();
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek();
		$self->_save();
		
		return $self->_getAct($actId)
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime();
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub push {
		my ($self, $lifetime) = @_;
		$lifetime //= $self->{defaultLifetime};
		
		opendir my $dh, "$self->{path}/acts";
		my @directories = <$dh>
		closedir $fh;
		my $actId = @directories;
		
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

		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot remove.");
		$self->{k}->remove($actId) or return (errorMessage => "Act $actId has already been removed, cannot remove.");
		
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	# I want some type of searching functionality, so that I don't add duplicate words :|.
	# ((should only search non-deleted acts))). Wait ... should it search deleted acts? Sigh ... recycling policies hurt my brain.
	

	sub edit {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot edit.");

		return $self->_setAct();
		# wait ... does karma even have an interface function to modify ttl? A: no! that makes my options fewer, and choices easier.
		
		# should I return a handler to change the lifetime .... mumble mumble, too many handlers spoils the soup ... but this will be the last one! Right? 
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot lookup.");
		
		return $self->_getAct($actId);
	}
	
}


# lifetime is a separate thing from lookup.
# ah, but entering lifetime when pushing -- to do that, i need to check recycling laws.

1;

# I might have to decouple lifetime
# I might want to return IDs to the console rather than through vim ... myeh, idk.


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

1;

# it's a ridiculous thing to cycle without first priming if logging is going to be a part of the system.
# A: it depends on the scope of the system, and atomicity of cycling. For "here's something to think about", which is achieved at a glance, cycle-cycle-cycle is a valid use case.


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