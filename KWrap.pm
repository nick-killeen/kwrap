# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;

# I will probably want this to be an arg to KWrap, or default ...


package KWrap {
	sub new {
		my ($class, %args) = @_;
		
		# there must be no naming collisions with Karma
		# TODO, handle eternal 5 5 5 5 5 5 5 5 5 5 5 lifetime
		my $self = {
			path            => "KWrap",
			slurpTo         => sub { system "vim $_[0]"; },   # :: path -> void (opens stdin port)
			spewFrom        => sub { system "vim -R $_[0]"; } # :: path -> void (opens stdout port)
			defaultLifetime => undef; # undef will cause complaints if no lifetime is provided (unless recycle policy is unfair)
			eagerLookup     => 1; # lookupAfter => 0 | 1 .... do we want to look up acts that we cycle, or is it okay just to show the ID?    # TODO
			
			# I need to have the same default recycling policy?
			
		};

		my %karmaArgs = %args;
		delete $karmaArgs{$_} for (keys %$self);
		$self->{k} = Karma->new(%karmaArgs);
		
		# The Karma constructor will complain if it had recieved any invalid
		# arguments, so, at this point, we needn't question that %args make(s)
		# sense either to Karma or KWrap.
		$self->{$_} = $args{$_} for (keys %args);
		
		bless $self, $class;
		
		if (-e "$self->{path}/Karma") {
			$self->{k}->load(path => "$self->{path}/Karma");
		} else {
			$self->{k}->save(path => "$self->{path}/Karma");
		}
	
		mkdir "$self->{path}/acts";
		
		return $self;
	}
	
	# this currently trusts the veracity of IDs ... feel free to die otherwise.
	sub _yieldAct {
		my ($self, $actId) = @_;
		
		if ($self->{eagerLookup}) {
			$self->{spewFrom}->("$self->{path}/acts/$actId");
		}
		return (actId => $actId);
		
	}
	
	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle();
		return $self->_yieldAct($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek();
		return $self->_yieldAct($actId)
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime();
		return $self->_yieldAct($actId);
	}
	
	sub push {
		my ($self, $lifetime) = @_;
		
		# make sure lifetime isn't overtly invalid.
		
		$lifetime //= $self->{defaultLifetime};
	
		if ($self->{recycle} eq "eternal" or $self->{recycle} eq "destruct") {
			$lifetime //= 1; # give any valid (non-zero) lifetime if none is provided; they are all treated the same.
		}
		
		my $actId = $self->{k}->length();
		$self->{k}->push($actId, $lifetime);

		$self->{slurpTo}->("$self->{path}/acts/$actId");
		
		return (actId => $actId);
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
		
		return ();
	}
	
	sub save {
		my ($self) = @_;
	
		$self->{k}->save(path => "$self->{path}/Karma");
	}
	
	sub remove {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot remove.");
		# actId must also be in Karma to be able to remove it.
		
		# Oh, removal should definitely only be soft.
		
		$self->{k}->remove($actId);
		
		# ??? what should this return ???  I think it's good for it to unconditionally spew, so that you can verify which act it removed ... but spewing is disorientating.
		# well .. for them to have performed a removal, they should have just spewed? so no need to do so again, 
		# just yield the actId so that they can once more check they entered the same thing as above.
		return ();
	}
	
	sub edit {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot edit.");
		
		$self->{slurpTo}->("$self->{path}/acts/$actId");
		
		return ();
	}
	
	# in general, don't go telling people their ttl unless they ask,
	# and don't ask if their answer doesn't matter.
	
	
	sub lookup {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot lookup.");
		
		$self->{spewFrom}->("$self->{path}/acts/$actId");
		
		
		return (actId => $actId, lifetime => $self->{k}->lifetime($actId)); # caller can choose to ignore based on recycling policy.
		# this is purely an interface function, 
		
		#return (errorMessage => undef); # a triple return code of emsg, ttl, id; leaves things to the caller ... which is somewhat what i want to do, wrt. inversion
		                                # but is there any way to make it neat, or neater?
	}
	
	sub lifetime {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does not exist, cannot check lifetime.");
		
		return (lifetime => self->{k}->lifetime($actId));
	}
	
	
	# sub lifetime ...
	
	# Do I also want a way to buff (or otherwise edit) ttl?
	# I should have an option for KWrap to work w/ eternal.
	
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