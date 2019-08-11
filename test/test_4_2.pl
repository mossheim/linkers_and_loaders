#!/usr/bin/env perl
# -*- perl -*-
#
# Tests for 4.2: Common blocks

use diagnostics;
use warnings;
use strict;
use Test::More qw( no_plan );
use lib 'lib';
use ObjectFormatIO;
use StorageAllocation;
use File::Basename; # for dirname

####################################################################################################
# Test cases
####################################################################################################

my $data_dir =  dirname(__FILE__) . "/data_4_2/";

sub test_file {
    my @args = map { $data_dir . $_ } @_;
    my $test_name = shift @args;
    my @input_files = @args;
    my $output_file = $test_name . "_out";
    my $exp_file = $test_name . "_expected";

    for my $input_file (@input_files) {
        -f $input_file || die "Input file $input_file does not exist";
    }
    -f $exp_file || die "Expected file $exp_file does not exist";

    my @input_data = map { { ObjectFormatIO::read($_) } } @input_files;
    my $output_file_data = StorageAllocation::calc_storage_allocation(\@input_data);
    ObjectFormatIO::write($output_file, $output_file_data);

    my $diff = `diff $output_file $exp_file`;
    unlink $output_file;
    is($diff, '', "Test case: $test_name");
}

test_file("obj1", "obj1");
test_file("obj2", "obj2");
test_file("obj3", "obj3");
test_file("obj1_obj2", "obj1", "obj2");
test_file("obj1_obj3", "obj1", "obj3");
test_file("obj2_obj3", "obj2", "obj3");
test_file("obj1_obj2_obj3", "obj1", "obj2", "obj3");
