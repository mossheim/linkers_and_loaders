#!/usr/bin/env perl
# -*- perl -*-
#
# Tests for 5.2, 5.3: Symbol value resolution & common blox

use diagnostics;
use warnings;
use strict;
use Test::More qw( no_plan );
use lib 'lib';
use ObjectFormatIO;
use StorageAllocation;
use SymbolResolution;
use File::Basename; # for dirname

####################################################################################################
# Test cases
####################################################################################################

my $data_dir;

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
    my %global_symbol_table = SymbolResolution::create_global_symbol_table(\@input_data);
    my %output_file_data = StorageAllocation::calc_storage_allocation(\@input_data);
    SymbolResolution::resolve_symbol_values(\@input_data, \%global_symbol_table);
    # just rely on global table output
    # ObjectFormatIO::write($output_file, \%output_file_data);
    SymbolResolution::write_global_symbol_table($output_file, \%global_symbol_table);

    my $diff = `diff $output_file $exp_file`;
    unlink $output_file;
    is($diff, '', "Test case: $test_name");
}

$data_dir =  dirname(__FILE__) . "/data_5_2/";
test_file("obj1", "obj1");

$data_dir =  dirname(__FILE__) . "/data_5_3/";
