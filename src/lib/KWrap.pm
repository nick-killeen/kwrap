# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;
use Act;

our $VERSION = '0.01';

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
		$self->{k}->save(path => "$self->{path}/Karma");

		
		# don't forget to listen for undefs ... this will result in a lot of repeated code,
		# try to emulate a save function wrapper for cycle, peek, prime &c, or at least
		# hide the path interpolation ...
		
		
		my $act = KWrap::Act->new("$self->{path}/$actId");
		$act->addLog($log);
		
		return $act->getProperties();
	}
	
	sub peek {
		my ($self) = @_;
		
		my $actId = $self->{k}->peek();
		$self->{k}->save(path => "$self->{path}/Karma");
		
		my $act = KWrap::Act->new("$self->{path}/$actId");
		return $act->getProperties();
	}
	
	sub prime {
		my ($self) = @_;
		
		my $actId = $self->{k}->prime();
		$self->{k}->save(path => "$self->{path}/Karma");
		
		my $act = KWrap::Act->new("$self->{path}/$actId");
		return $act->getProperties();
	}
	
	
	sub push {
		my ($self, $actProperties, $lifetime) = @_;
		# arg val done by karma and act classes
		
		my $actId = $self->{k}->length();
		$self->{k}->push($actId, $lifetime);
		$self->{k}->save(path => "$self->{path}/Karma");
	
		mkdir "$self->{path}/$actId";
		my $act = KWrap::Act->new("$self->{path}/$actId");
		$act->setProperties($actProperties);
	}
	
	sub relax {
		my ($self) = @_;
		$self->{k}->relax();
		$self->{k}->save(path => "$self->{path}/Karma");
	}
	
	sub remove {
	
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

__END__

=head1 NAME

...

=head1 SYNOPSIS

...

=head1 DESCRIPTION

...


=head1 SEE ALSO

...

=head1 AUTHOR

Nicholas Killeen<lt>nicholas.killeen2@gmail.com<gt>

=head1 COPYRIGHT AND LICENSE

GNU General Public License v3.0, as at <lt>https://github.com/nick-killeen/kwrap/<gt>.

=cut
