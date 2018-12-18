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
# slurpHandle,
# matches

package KWrap::CODE {
	our $CYCLE_ON_EMPTY         = "Nothing to cycle.";
	our $EDIT_BAD_ID            = "Cannot edit with invalid actId.";
	our $LOOKUP_BAD_ID          = "Cannot lookup with invalid actId.";
	our $PEEK_ON_EMPTY          = "Nothing to peek.";
	our $PRIME_ON_EMPTY         = "Nothing to prime.";
	our $PUSH_BAD_LIFETIME      = "Cannot push with invalid lifetime.";
	our $REMOVE_ALREADY_REMOVED = "Cannot remove act that has already been removed.";
	our $REMOVE_BAD_ID          = "Cannot remove with invalid actId.";
}; 

package KWrap {
	sub new {
		my ($class, %args) = @_;
	
		my $self = {
			defaultLifetime => undef, # undef will cause complaints if no lifetime is provided (unless recycle policy isn't fair)
		
			path => "KWrap",
			
			slurpTo => sub { # :: str -> bool; writes from world to file path 'str'. 0 return code aborts push.
				my $c = "";
				
				while (<>) {
					chomp $_;
					last if ($_ eq '');
					$c .= "$_\n";
				}
				
				if ($c eq '') {
					return 0;
				} else {
					open my $fh, ">", $_[0];
					print $fh $c;
					close $fh;
					return 1;
				}
			},
			
			spewFrom => sub { # :: str -> void; writes from file path 'str' to world.
				open my $fh, "<", $_[0];
				print do { local $/ = undef; <$fh> };
				close $fh;
			}
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
	

	sub _actIdExists {
		my ($self, $actId) = @_;
		
		return (defined $actId and $actId =~ /^\d+$/ and -e "$self->{path}/acts/$actId");
	}
	
	sub _allActIds {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}/acts";
		my @contents = readdir $dh;
		@contents = grep {!/^\./} @contents; # ignore contents beginning with '.', including the '.' and '..' directories.
		closedir $dh;
		
		return @contents;
	}
	
	sub _getAct {
		my ($self, $actId) = @_;

		-e "$self->{path}/acts/$actId" or die "_getAct expects validity of actIDs, but was provided an actId that does not exist.";
		
		return (
			actId      => $actId,
			lifetime   => $self->{k}->lifetime($actId),
			spewHandle => sub { $self->{spewFrom}->("$self->{path}/acts/$actId", @_) } # note that we feed in additional arguments
		);
	}
	
	sub _save {
		my ($self) = @_;
	
		$self->{k}->save(path => "$self->{path}/Karma");
		
		return 1;
	}
	
	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle() // return (error => $KWrap::CODE::CYCLE_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	
	sub edit {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId) or return (error => $KWrap::CODE::EDIT_BAD_ID);

		return (
			actId       => $actId,
			lifetime    => $self->{k}->lifetime($actId),
			slurpHandle => sub { $self->{slurpTo}->("$self->{path}/acts/$actId", @_) } 
		);
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId) or return (error => $KWrap::CODE::LOOKUP_BAD_ID);
		
		return $self->_getAct($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek() // return (error => $KWrap::CODE::PEEK_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime() // return (error => $KWrap::CODE::PRIME_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub push {
		my ($self, $lifetime) = @_;
		$lifetime //= $self->{defaultLifetime};
		defined $lifetime and $lifetime =~ /^\d+$/ and $lifetime > 0 or return (error => $KWrap::CODE::PUSH_BAD_LIFETIME);
		
		
		my $actId = $self->_allActIds();
	
		return (
			actId       => $actId,
			lifetime    => $lifetime,
			slurpHandle => sub { $self->{slurpTo}->("$self->{path}/acts/$actId", @_) and $self->{k}->push($actId, $lifetime) and $self->_save(); } # slurping and pushing must be done at once to achieve atomicity and synchronicity of KW and K ... TD. comment about return code.
		);  # every time a slurpHandle is returned, it must be called immediately (before any other state-changing interface function), or never; otherwise strange unintended behaviour will present itself.
			# it isn't difficult to enforce this, but it adds unnecessary complexity where I think it is very difficult to unintentionally abuse this promise of linearity.
			# no, not just this -- everything should be linear. this is also enforcable to some extent
		
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
		$self->_save();
		
		return ();
	}
	
	sub remove {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId) or return (error => $KWrap::CODE::REMOVE_BAD_ID);
 		
		$self->{k}->remove($actId) or return (error => $KWrap::CODE::REMOVE_ALREADY_REMOVED);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	# search must return matches in ascending order.
	sub search {
		my ($self, $substr) = @_;
		$substr //= "";
				
		my @matches = ();
		for ($self->_allActIds()) {
			open my $fh, "<", "$self->{path}/acts/$_" or die;
			local $/ = undef;
			CORE::push @matches, $_ if (index(lc <$fh>, lc $substr) != -1);
			close $fh;
		}
		
		return (matches => \@matches);
	}
	
	# TODO List:
	# - consider how runKW can be modified to include multiple buckets by resolving ids.
	# - docs
	# - tests
}

1;

