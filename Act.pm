use warnings;
use strict;

package KWrap::Act {
	sub new {
		my ($class, $path, $id) = @_;
		my $self = {
			path => $path,
			id => $id
		};
		return bless $self, $class;
	}
	
	sub getProperties {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}/$self->{id}";
		my @keys = readdir $dh;
		closedir $dh;
		
		@keys = grep {!/^\.\.?$/} @keys; # ignore '.', '..'

		my %properties = ();
		for (@keys) {
			chomp $_;
			open my $fh, "<", "$self->{path}/$self->{id}/$_";
			$properties{$_} = <$fh>;
			close $fh;
		}
		
		return %properties;
		
	}
	
	sub setProperties {
		my ($self, %properties) = @_;
		
		die "Cannot set reserved property 'id'." if defined $properties{id};
		
		for (keys %properties) {
			open my $fh, ">", "$self->{path}/$self->{id}/$_";
			print $fh $properties{$_};
			close $fh;
		}
	}
	
	# will want a mechanism to edit properties, add additional properties, delete ...

};

1;