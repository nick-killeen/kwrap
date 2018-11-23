# A wrapper for Karma that presumes Acts are directories containing plain-text
# files.

use warnings;
use strict;

use Data::Dumper;
use Karma;
use Act::SpecialAct;

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
		
		$self->{k}->load(path => "$self->{path}/Karma");
		
		return $self;
	}
	
	sub cycle {
	
	}
	
	sub lifetime {
	
	}
	
	sub peek {
		my $self = @_;
		my $actId = $self->{k}->peek();
		my $act = Act::SpecialAct->new("$self->{path}/$actId");
		# ...
		
	}
	
	sub prime {
	
	}
	
	sub push {
		my ($self, $name, $description, $lifetime) = @_; #
		name, description should be extensible properties of the ABC act.
		# arg val done by karma and act classes.
		
		my $actId = $self->{k}->length();
		$self->{k}->push($actId, $lifetime);
		$self->{k}->save(path => "$self->{path}/Karma");
	
		mkdir "$self->{path}/$actId";
		my $act = Act::SpecialAct->new("$self->{path}/$actId");
		$act->amISpecial();
		$act->setName($name);
		$act->setDescription($description);
	}
	
	sub relax {
		my $self = @_;
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
#sub remove($self)
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
