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
			path     => "KWrap",
			slurpTo  => sub { system "vim $_[0]"; },   # :: path -> void (opens stdin port)
			spewFrom => sub { system "vim -R $_[0]"; } # :: path -> void (opens stdout port)
		};

		my %karmaArgs = %args;
		delete $karmaArgs{$_} for (keys %$self);
		$self->{k} = Karma->new(%karmaArgs);
		
		# The Karma constructor will complain if it had recieved any invalid
		# arguments, so, at this point, we needn't question that the %args make
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
	
	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle();
		return $self->lookup($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek();
		
		return $self->lookup($actId)
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime();
		
		return $self->lookup($actId);
	}
	
	
	sub push {
		my ($self, $lifetime) = @_;
		
		my $actId = $self->{k}->length();
		$self->{k}->push($actId, $lifetime); # handle death caused by invalid lifetime gracefully?


		$self->{slurpTo}->("$self->{path}/acts/$actId");
		
		return (errorMessage => undef); #  Do i want to let the caller know the ID I pushed? No, you should vimify that somehow ... have it the first line of the act.
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
		
		return (errorMessage => undef);
	}
	
	sub save {
		my ($self) = @_;
	
		$self->{k}->save(path => "$self->{path}/Karma");
		# this isn't an evaluatory fn, no retval needed.
	}
	
	sub remove {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does no exist, cannot remove.");
		# actId must also be in Karma to be able to remove it.
		
		$self->{k}->remove($actId);
		
		return $self->lookup($actId);
	}
	
	sub edit {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does no exist, cannot edit.");
		
		$self->{slurpTo}->("$self->{path}/acts/$actId");
		
		return (errorMessage => undef);
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		(-e "$self->{path}/acts/$actId") or return (errorMessage => "Act $actId does no exist, cannot lookup.");
		
		$self->{spewFrom}->("$self->{path}/acts/$actId");
		
		return (errorMessage => undef);
	}
	
	# Do I also want a way to buff (or otherwise edit) ttl?
	# I should have an option for KWrap to work w/ eternal.
	
}

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