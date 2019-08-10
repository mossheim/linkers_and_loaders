use diagnostics;
use warnings;
use strict;
use Test::More qw( no_plan );
use lib '..';
use ObjectFormatIO;

####################################################################################################
# Test cases
####################################################################################################

sub test_file {
    my $input_file = shift;
    my $output_file = $input_file . "_out";
    my $exp_file = $input_file . "_expected";

    -f $input_file || die "Input file $input_file does not exist";
    -f $exp_file || die "Expected file $exp_file does not exist";

    my %object_data = ObjectFormatIO::read($input_file);
    ObjectFormatIO::write($output_file, \%object_data);
    my $diff = `diff $output_file $exp_file`;
    unlink $output_file;
    is($diff, '', "Input file: $input_file");
}

test_file("data/object1");
test_file("data/object2");
test_file("data/object3");
