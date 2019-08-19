#!/usr/bin/env perl
# -*- perl -*-
#
# Tests for 5.1, 5.2, 5.3: Symbol resolution

use diagnostics;
use warnings;
use strict;
use lib 'lib';
use ObjectFormatIO;
use SymbolResolution;
use StorageAllocation;
use SimpleTest;
use File::Basename; # for dirname

####################################################################################################
# Test cases
####################################################################################################

sub test_func_1 {
    my ($input, $output) = @_;
    my @input_data = map { { ObjectFormatIO::read($_) } } @{$input};
    my %global_symbol_table = SymbolResolution::create_global_symbol_table(\@input_data);
    SymbolResolution::write_global_symbol_table($output, \%global_symbol_table);
}

sub test_func_23 {
    my ($input, $output) = @_;
    my @input_data = map { { ObjectFormatIO::read($_) } } @{$input};
    my %global_symbol_table = SymbolResolution::create_global_symbol_table(\@input_data);
    my %output_file_data = StorageAllocation::calc_storage_allocation(\@input_data);
    SymbolResolution::resolve_symbol_values(\@input_data, \%global_symbol_table, $output_file_data{sections});
    # just rely on global table output
    SymbolResolution::write_global_symbol_table($output, \%global_symbol_table);
}

my $data_dir;
my $func;

$data_dir =  dirname(__FILE__) . "/data_5_1/";
$func = \&test_func_1;
SimpleTest::simple_test($func, $data_dir, "obj1", "obj1");
SimpleTest::simple_test($func, $data_dir, "obj12", "obj1", "obj2");

$data_dir =  dirname(__FILE__) . "/data_5_2/";
$func = \&test_func_23;
SimpleTest::simple_test($func, $data_dir, "obj1", "obj1");

$data_dir =  dirname(__FILE__) . "/data_5_3/";
SimpleTest::simple_test($func, $data_dir, "obj1", "obj1");
SimpleTest::simple_test($func, $data_dir, "obj2", "obj2");
SimpleTest::simple_test($func, $data_dir, "obj12", "obj1", "obj2");
