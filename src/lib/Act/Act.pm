use warnings;
use strict;

package Act::Act { # TODO this should only be an ABC, with various SpecialActs existing, one of which is this implementation
	sub new {
		my ($class, $path) = @_;
		my $self = {
			path => $path
		};
		return bless $self, $class;
	}
	
	sub getDescription {
		my $self = @_;
		
		open my $fh, "<", "$self->{path}/description";
		my $name = <$fh>;
		close $fh;
		
		return $name;
	}
	
	sub setDescription {
		my ($self, $description) = @_;
		
		# -- validation should occur here
		
		open my $fh, ">", "$self->{path}/description";
		print $fh $description;
		close $fh;
	}
	
	sub getName {
		my $self = @_;
		
		open my $fh, "<", "$self->{path}/name";
		my $name = <$fh>;
		close $fh;
		
		return $name;
	}
	
	sub setName {
		my ($self, $name) = @_;
		
		# -- validation should occur here
		
		open my $fh, ">", "$self->{path}/name";
		print $fh $name;
		close $fh;
	}
};

1;