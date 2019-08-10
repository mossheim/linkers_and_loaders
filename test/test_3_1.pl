#!/usr/bin/env perl
# -*- perl -*-
#
# Tests for 3.1: Read and write object file

use diagnostics;
use warnings;
use strict;
use Test::More qw( no_plan );
use lib 'lib';
use ObjectFormatIO;
use File::Basename; # for dirname

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

my $data_dir =  dirname(__FILE__) . "/data_3_1/";
test_file($data_dir . "empty");
test_file($data_dir . "bss_only");
test_file($data_dir . "secs");
test_file($data_dir . "secs_syms");
test_file($data_dir . "secs_syms_relocs");
