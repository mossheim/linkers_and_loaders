#!/usr/bin/env perl
# -*- perl -*-
#
# Tests for 4.1, 4.2, 4.3: Storage allocation, common blocks

use diagnostics;
use warnings;
use strict;
use lib 'lib';
use ObjectFormatIO;
use StorageAllocation;
use SimpleTest;
use File::Basename; # for dirname

####################################################################################################
# Test cases
####################################################################################################

sub test_func {
    my ($input, $output) = @_;
    my @input_data = map { { ObjectFormatIO::read($_) } } @{$input};
    my %output_file_data = StorageAllocation::calc_storage_allocation(\@input_data);
    ObjectFormatIO::write($output, \%output_file_data);
}

my $data_dir;

$data_dir =  dirname(__FILE__) . "/data_4_1/";
SimpleTest::simple_test(\&test_func, $data_dir, "obj1", "obj1");
SimpleTest::simple_test(\&test_func, $data_dir, "obj3", "obj3");
SimpleTest::simple_test(\&test_func, $data_dir, "obj1_obj2", "obj1", "obj2");
SimpleTest::simple_test(\&test_func, $data_dir, "obj2_obj3", "obj2", "obj3");

$data_dir =  dirname(__FILE__) . "/data_4_2/";
SimpleTest::simple_test(\&test_func, $data_dir, "obj1", "obj1");
SimpleTest::simple_test(\&test_func, $data_dir, "obj2", "obj2");
SimpleTest::simple_test(\&test_func, $data_dir, "obj3", "obj3");
SimpleTest::simple_test(\&test_func, $data_dir, "obj1_obj2", "obj1", "obj2");
SimpleTest::simple_test(\&test_func, $data_dir, "obj1_obj3", "obj1", "obj3");
SimpleTest::simple_test(\&test_func, $data_dir, "obj2_obj3", "obj2", "obj3");
SimpleTest::simple_test(\&test_func, $data_dir, "obj1_obj2_obj3", "obj1", "obj2", "obj3");

$data_dir =  dirname(__FILE__) . "/data_4_3/";
SimpleTest::simple_test(\&test_func, $data_dir, "obj1", "obj1");
SimpleTest::simple_test(\&test_func, $data_dir, "obj2", "obj2");
SimpleTest::simple_test(\&test_func, $data_dir, "obj3", "obj3");
SimpleTest::simple_test(\&test_func, $data_dir, "obj4", "obj4");
SimpleTest::simple_test(\&test_func, $data_dir, "obj5", "obj5");
SimpleTest::simple_test(\&test_func, $data_dir, "obj1_obj2", "obj1", "obj2");
SimpleTest::simple_test(\&test_func, $data_dir, "obj12345", "obj1", "obj2", "obj3", "obj4", "obj5");
