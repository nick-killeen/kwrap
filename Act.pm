use warnings;
use strict;

package KWrap::Act {
	sub new {
		my ($class, $path, $actId) = @_;
		
		my $self = {
			path => $path,
			actId => $actId
		};
		bless $self, $class;
		
		mkdir "$self->{path}/$self->{actId}";
		
		return $self;
	}
	
	sub getProperties {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}/$self->{actId}";
		my @keys = readdir $dh;
		closedir $dh;
		
		@keys = grep {!/^\.\.?$/} @keys; # ignore '.', '..'

		my $properties = {id => $self->{actId}};
		for (@keys) {
			chomp $_;
			open my $fh, "<", "$self->{path}/$self->{actId}/$_";
			$properties->{$_} = <$fh>;
			close $fh;
		}
		
		return $properties; # the disorder is mildly inconvenient.
		
	}
	
	sub setProperties {
		my ($self, $properties) = @_;

		for (keys %$properties) {
			open my $fh, ">", "$self->{path}/$self->{actId}/$_";
			print $fh $properties->{$_};
			close $fh;
		}
	}
	
	# will want a mechanism to edit properties, add additional properties, delete ...

};

1;