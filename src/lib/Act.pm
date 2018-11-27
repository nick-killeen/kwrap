use warnings;
use strict;

package KWrap::Act {
	sub new {
		my ($class, $path) = @_;
		my $self = {
			path => $path
		};
		return bless $self, $class;
	}
	
	sub getProperties {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}";
		my @keys = readdir $dh;
		closedir $dh;
		
		@keys = grep {!/^\.\.?$/} @keys; # ignore '.', '..'

		my %properties = ();
		for (@keys) {
			chomp $_;
			open my $fh, "<", "$self->{path}/$_";
			$properties{$_} = <$fh>;
			close $fh;
		}
		
		return %properties;
		
	}
	
	sub setProperties {
		my ($self, $properties) = @_;

		mkdir "$self->{path}/$LOG_FOLDER";
		
		for (keys %$properties) {
			open my $fh, ">", "$self->{path}/$_";
			print $fh $properties->{$_};
			close $fh;
		}
	}
	
	# will want a mechanism to edit properties, add additional properties, delete ...

};

1;