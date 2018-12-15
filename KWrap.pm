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
			},
			
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
	
	sub _setAct {
		my ($self, $actId) = @_;
		
		return (
			actId       => $actId,
			lifetime    => $self->{k}->lifetime($actId),
			slurpHandle => sub { $self->{slurpTo}->("$self->{path}/acts/$actId", @_) and $self->_save(); } # slurping and saving must be done at once to achieve atomicity and synchronicity of KW and K ... TD. comment about return code.
		);
	}
	

	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle() // return (error => "Nothing to cycle.");
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
		
		my $actId = $self->{k}->peek() // return (error => "Nothing to peek.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime() // return (error => "Nothing to prime.");
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub push {
		my ($self, $lifetime) = @_;
		$lifetime //= $self->{defaultLifetime};
		$lifetime // return (error => "No lifetime provided to push.");
		$lifetime =~ /^\d+$/ and $lifetime > 0 or return (error => "Invalid lifetime '$lifetime'.");
		
		my $actId = $self->_allActIds();
		
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
	# - default slurping and spewing one liners, or gobble from STDIN, STDOUT?
	# - do i want multiple buckets to be a part of one KW? in that case, I need id prefixes ... wait, the parsing of which bucket based off these would be a part of runKW?
	# - nice docs, acknowledge badnesses such aas error messages.
}

1;

