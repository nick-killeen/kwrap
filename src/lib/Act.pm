use warnings;
use strict;

# TODO: refactor to remove necessity of manifest by using <"path/*">. ... this is typeglob stuff, avoid if possible,
# instead consider readdir.

# I don't want this to be exported ... so do I have to package it? 
my $LOG_FOLDER = ".logs"; # must begin with .

package KWrap::Act {
	sub new {
		my ($class, $path) = @_;
		my $self = {
			path => $path
		};
		return bless $self, $class;
	}

	sub addLog {
		my ($self, $log) = @_;
		
		opendir my $dh, "$self->{path}/$LOG_FOLDER/";
		my @logs = readdir $dh;
		closedir $dh;
		
		@logs = grep {!/^\./} @logs; # ignore '.', '..'.
		
		my $nextLog = @logs;
		open my $fh, ">", "$self->{path}/$LOG_FOLDER/$nextLog";
		print $fh $log;
		close $fh;
	}
	
	sub getProperties {
		my ($self) = @_;
		
		opendir my $dh, "$self->{path}";
		my @keys = readdir $dh;
		closedir $dh;
		
		@keys = grep {!/^\./} @keys; # ignore '.', '..', (and .hidden directories such as $LOG_FOLDER).

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
		
		# lazy arg validation ... in the future, must be strict w/ file names.
		# allow the creation of private properties with . names?
		$_ ne $LOG_FOLDER or die for (keys %$properties);

		mkdir "$self->{path}/$LOG_FOLDER";
		
		for (keys %$properties) {
			open my $fh, ">", "$self->{path}/$_";
			print $fh $properties->{$_};
			close $fh;
		}
	}

};

1;