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

	sub setProperties {
		my ($self, $properties) = @_;
		
		# lazy arg validation
		$_ eq "properties" and die or $_ eq "logs" and die for (keys %$properties);

		mkdir "$self->{path}/logs";
		
		open my $fh, ">", "$self->{path}/properties";
		print $fh "$_\n" for (keys %$properties);
		close $fh;
		
		for (keys %$properties) {
			open my $fh, ">", "$self->{path}/$_";
			print $fh $properties->{$_};
			close $fh;
		}
	}
	
	sub addLog {
		# todo
	}
	
	sub getProperties {
		my ($self) = @_;
		
		open my $fh, "<", "$self->{path}/properties";
		my @keys = <$fh>;
		close $fh;
		
		my %properties = ();
		for (@keys) {
			chomp $_;
			open my $fh, "<", "$self->{path}/$_";
			$properties{$_} = <$fh>;
			close $fh;
		}
		
		return %properties;
		
	}
};

1;