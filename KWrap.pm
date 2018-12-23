# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.
#
# Public KWrap functions return hashes with some number of:
#
# - actId:       The unique identifying actId of the requested Act.
#
# - error:       A code or message indicating that a request was not fulfilled
#                in the way that might have been expected by the caller;
#                all error values are defined in KWrap::CODE.
#
# - lifetime:    The lifetime of the requested Act. Is 0 if the Act is no longer
#                a part of the Karmic cycle.
#
# - matches:     List of actIds that match the substring sent to 'search', in
#                ascending order.
#
# - slurpHandle: Decorated version of the 'slurpTo' constructor argument;
#                opening this handle will complete either the 'push' or 'edit'
#                request by accepting input from 'slurpTo'. 'push' slurpHandles
#                will return 1 on success, and 0 on failure.
#
# - spewHandle:  Decorated version of the 'spewFrom' constructor argument;
#                opening this handle will cause the requested Act to have its
#                contents printed by way of 'spewFrom'.

use warnings;
use strict;

use Data::Dumper;
use Karma;

package KWrap::CODE {
	our $CYCLE_ON_EMPTY         = "Nothing to cycle.";
	our $EDIT_BAD_ID            = "Cannot edit with invalid actId.";
	our $LOOKUP_BAD_ID          = "Cannot lookup with invalid actId.";
	our $PEEK_ON_EMPTY          = "Nothing to peek.";
	our $PRIME_ON_EMPTY         = "Nothing to prime.";
	our $PUSH_BAD_LIFETIME      = "Cannot push with invalid lifetime.";
	our $REMOVE_ALREADY_REMOVED = "Cannot remove Act no longer in the cycle.";
	our $REMOVE_BAD_ID          = "Cannot remove with invalid actId.";
}; 

package KWrap {
	sub new {
		my ($class, %args) = @_;
		# Valid %args keys are 'defaultLifetime', 'path', 'slurpTo' -- described
		# below; and 'allowDuplicateActIds', 'indexGenerator', 'recycle' --
		# described in the Karma docs.
	
		my $self = {
			defaultLifetime => undef,
		
			path => "KWrap",
			
			# The 'slurpTo' subroutine provides a method by which an Act can be
			# written for storage; namely, it takes in a file path as an
			# argument, and accepts input from the user which it writes into
			# that path.
			# 
			# This method will be used when calling 'edit' or 'push', and in the
			# latter case, a return code of 0 will abort the push.
			# 
			# The default method reads lines from STDIN until it encounters a
			# a\n^D\n or \n^Z\n on a Windows System, or \n^D on Linux.
			#
			# Ctrl-C aborts on Linux, but on Windows .... TODO, either explain the difficulties or solve them.
			slurpTo => sub {
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
			
			# The 'spewFrom' subroutine provides a method by which an Act can be
			# read from storage; it takes in a file path as an argument, and
			# echoes the contents of this file to the user.
			#
			# The default method prints the files contents directly to STDOUT.
			spewFrom => sub {
				open my $fh, "<", $_[0];
				print do { local $/ = undef; <$fh> };
				close $fh;
			}
		};

		# Remove any KWrap %args, and we are left with Karma %args.
		my %karmaArgs = %args;
		delete $karmaArgs{$_} for (keys %$self);
		$self->{k} = Karma->new(%karmaArgs);
		# The Karma constructor will complain if it had recieved any invalid
		# arguments, so, at this point, we needn't question that %args make(s)
		# sense either to Karma or KWrap.
		$self->{$_} = $args{$_} for (keys %args);
		
		bless $self, $class;
	
		# If the recycle policy isn't "fair", lifetime doesn't really have any
		# meaning and instead becomes a hassle. An arbitrary fallback default of
		# 1 can be provided.
		if (defined $self->{recycle} and ($self->{recycle} eq "eternal"
			or $self->{recycle} eq "destruct")) {
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
	
	# An Act "exists" if it has been pushed and successfully slurped into; viz.,
	# the corresponding file exists. An Act will still exists even if it has
	# been removed, or is no longer in the Karmic cycle.
	sub _actIdExists {
		my ($self, $actId) = @_;
		
		return (defined $actId and $actId =~ /^\d+$/ and
			-e "$self->{path}/acts/$actId");
	}
	
	# List of all actIds that "exist".
	sub _allActIds {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}/acts";
		my @contents = readdir $dh;
		@contents = grep {!/^\./} @contents; # ignore '.' and '..' directories
		closedir $dh;
		
		return @contents;
	}
	
	# Get information about an Act that already exists.
	sub _getAct {
		my ($self, $actId) = @_;

		-e "$self->{path}/acts/$actId" or die "_getAct expects validity of "
			. "actIDs, but was provided an actId '$actId' that does not exist.";
		
		return (
			actId      => $actId,
			lifetime   => $self->{k}->lifetime($actId),
			spewHandle => sub {
				$self->{spewFrom}->("$self->{path}/acts/$actId", @_);
			}
		);
	}
	
	sub _save {
		my ($self) = @_;
	
		$self->{k}->save(path => "$self->{path}/Karma");
		
		return 1;
	}
	
	sub cycle {
		my ($self) = @_;
		
		my $actId = $self->{k}->cycle()
			// return (error => $KWrap::CODE::CYCLE_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	
	sub edit {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId)
			or return (error => $KWrap::CODE::EDIT_BAD_ID);

		return (
			actId       => $actId,
			lifetime    => $self->{k}->lifetime($actId),
			slurpHandle => sub {
				$self->{slurpTo}->("$self->{path}/acts/$actId", @_);
			} 
		);
	}
	
	sub lookup {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId)
			or return (error => $KWrap::CODE::LOOKUP_BAD_ID);
		
		return $self->_getAct($actId);
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek()
			// return (error => $KWrap::CODE::PEEK_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime()
			// return (error => $KWrap::CODE::PRIME_ON_EMPTY);
		$self->_save();
		
		return $self->_getAct($actId);
	}
	
	# Open a decorated slurpHandle that the caller can execute to edit and push
	# an Act onto Karma.
	# Before you call push, you must promise:
	# - Any slurpHandles generated priorly will no longer be called.
	# - The returned slurpHandle will only be called only once, or not at all.
	sub push {
		my ($self, $lifetime) = @_;
		$lifetime //= $self->{defaultLifetime};
		defined $lifetime and $lifetime =~ /^\d+$/ and $lifetime > 0
			or return (error => $KWrap::CODE::PUSH_BAD_LIFETIME);
		
		
		my $actId = $self->_allActIds();
	
		return (
			actId       => $actId,
			lifetime    => $lifetime,
			slurpHandle => sub {
				return ($self->{slurpTo}->("$self->{path}/acts/$actId", @_) and
					$self->{k}->push($actId, $lifetime) and $self->_save());
			}
		);
	}
	
	sub relax {
		my ($self) = @_;
		
		$self->{k}->relax();
		$self->_save();
		
		return ();
	}
	
	# Remove an Act from the Karmic cycle; emulate its lifetime reaching 0.
	# It can still be edited and looked up.
	sub remove {
		my ($self, $actId) = @_;
		$self->_actIdExists($actId)
			or return(error => $KWrap::CODE::REMOVE_BAD_ID);
 		
		$self->{k}->remove($actId)
			or return (error => $KWrap::CODE::REMOVE_ALREADY_REMOVED);
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
}

1;

