#!/usr/bin/perl

# Define the list of Java processes you want to monitor
my @java_processes = "$ARGV[0]";

# Run the ps command to get the list of running processes
my $ps_output = `ps -ef | grep java`;

# Iterate through the list of Java processes and check if each one is running
foreach my $process (@java_processes) {
    if ($ps_output =~ /java.*$process/) {
        print "Message:Java process $process is running\n";
        print "Statistic:0\n";
        exit 0;
    }
}
print "Message:Java process $process is not running\n";
print "Statistic:1\n";
exit 1;