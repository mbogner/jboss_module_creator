#!/usr/bin/perl
use strict;
use warnings;

use Getopt::Long;
use LWP::Simple;
use File::Path;
use File::Copy;

my ( $source, $dir, $target, $clean ) = (
	'http://jdbc.postgresql.org/download/postgresql-9.2-1002.jdbc4.jar',
	'org/postgresql/driver', 'target', ''
);

exit 3
  unless GetOptions(
	's|source=s' => \$source,
	'd|dir=s'    => \$dir,
	't|target=s' => \$target,
	'clean'      => \$clean
  );

##############################################

sub read_filename_from_url {
	my ($url) = @_;
	if ( $source =~ m!.*/(.*)$! ) {
		return $1;
	}
}

##############################################

my $filename = read_filename_from_url($source);
if ( -e $filename ) {
	print "$filename already exists - skipping download\n";
}
else {
	print "downloading $filename from $source\n";
	getstore( $source, $filename );
}

##############################################

if ($clean) {
	print "cleaning up\n";
	rmtree $target;
}

##############################################

print "creating folders\n";
my $actual = $target;
mkdir $actual;
for my $subdir ( split( /\//, $dir ) ) {
	$actual .= "/$subdir";
	mkdir $actual;
}
$actual .= "/main";
mkdir $actual;

##############################################

print "creating module.xml\n";
my $module = $dir;
$module =~ s/\//./g;
open( my $xml, '>', "$actual/module.xml" ) or die $!;
print $xml <<EOF;
<?xml version="1.0" encoding="UTF-8"?>
<module xmlns="urn:jboss:module:1.0" name="$module">
    <resources>
        <resource-root path="$filename"/>
    </resources>
    <dependencies>
        <module name="javax.api"/>
        <module name="javax.transaction.api"/>
    </dependencies>
</module>
EOF
close $xml or die $!;
print "copy driver\n";
copy( $filename, "$actual/$filename" );

##############################################

print <<DRIVER;
######################
# You can use the following driver section:
######################

<driver name="postgresql" module="org.postgresql.driver">
	<xa-datasource-class>org.postgresql.xa.PGXADataSource</xa-datasource-class>
</driver>

######################
# And here is an example datasource
######################

<datasource jndi-name="java:jboss/datasources/TestDS" pool-name="TESTDS"
	enabled="true" jta="true" use-java-context="true" use-ccm="true">
	<connection-url>jdbc:postgresql:test</connection-url>
	<driver>postgresql</driver>
	<pool>
		<min-pool-size>5</min-pool-size>
		<max-pool-size>25</max-pool-size>
		<prefill>false</prefill>
		<use-strict-min>false</use-strict-min>
		<flush-strategy>FailingConnectionOnly</flush-strategy>
	</pool>
	<security>
		<user-name>someuser</user-name>
		<password>somepass</password>
	</security>
	<validation>
		<check-valid-connection-sql>SELECT 1</check-valid-connection-sql>
		<validate-on-match>false</validate-on-match>
		<background-validation>false</background-validation>
		<use-fast-fail>false</use-fast-fail>
	</validation>
</datasource>

######################
DRIVER

print "done\n";
exit 0;
