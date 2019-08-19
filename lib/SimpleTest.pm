use diagnostics;
use warnings;
use strict;
package SimpleTest;
use Test::More qw( no_plan );
use List::Util qw(reduce max);
use Data::Dumper qw(Dumper);

# Run a simple test
# This function does all the setup and validation for a validation test in this project
# You just pass in the function you want it to run to produce the 'out' file.

sub simple_test {
    my $test_func = shift || "No test func given";
    my $data_dir = shift || "No data dir given";
    my @args = map { $data_dir . $_ } @_;
    my $test_name = shift @args;
    my @input_files = @args;
    my $output_file = $test_name . "_out";
    my $exp_file = $test_name . "_expected";

    for my $input_file (@input_files) {
        -f $input_file || die "Input file $input_file does not exist";
    }
    -f $exp_file || die "Expected file $exp_file does not exist";

    $test_func->(\@input_files, $output_file);

    my $diff = `diff $output_file $exp_file`;
    unlink $output_file;
    is($diff, '', "Test case: $test_name");
}

1;
