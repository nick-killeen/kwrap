# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;
use Act;

package KWrap {
	sub new {
		my ($class, $path) = @_;
		# caller has the responsibility of making sure that the $path directory exists.
		my $self = {
			k    => Karma->new(),
			path => $path
		};
		bless $self, $class;

		if (-e "$self->{path}/Karma") {
			$self->{k}->load(path => "$self->{path}/Karma");
		} else {
			$self->{k}->save(path => "$self->{path}/Karma");
		}
		
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
	
	
	sub push {  # ???  ?? ?. . .TODO FIX
		my ($self, $lifetime, @propertyNames) = @_;
		# arg val done by karma and act classes
		
		# check lifetime validity first please lt3
		
		my $properties = {};
		for (@propertyNames) {
			print "% $_: ";
			$properties->{$_} = <>; # perform user input first so that things won't become half baked if we die half way through.
			                        # wait ... maybe it's good for things to become half baked, so partial progress is preserved if we die?
			chomp $properties->{$_};
		}
		
		
		my $actId = $self->{k}->length();
		$self->{k}->push($actId, $lifetime);
	
		my $act = KWrap::Act->new($self->{path}, $actId);
		$act->setProperties($properties);
		return $self->lookup($actId);
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
	}
	
	sub save {
		my ($self) = @_;
	
		$self->{k}->save(path => "$self->{path}/Karma");
	}
	
	sub remove {
		my ($self, $actId) = @_;
		
		$self->{k}->remove($actId); # this removes from the cycle, but doesn't remove the act's contents.
		return {okay => "I removed $actId"} # duplicate removal doesn't complain ... 
	}
	
	sub edit {
		my ($self, $actId) = @_;
		# print old, ask for new ... but i'm not usually resposible for printing! :(
		# i guess i don't need to print old, trusting that caller already knows.
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		
		my $act = KWrap::Act->new($self->{path}, $actId);
		return $act->getProperties();
	}
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

1;

# it's a ridiculous thing to cycle without first priming if logging is going to be a part of the system.


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