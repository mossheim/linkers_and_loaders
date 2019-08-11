#!/usr/bin/env perl
# -*- perl -*-
#
# Project 4.1: Storage allocation
use strict;
use lib 'lib';
use ObjectFormatIO;
use StorageAllocation;

# args: last is output file, rest are input
my @files = @ARGV;
$#files >= 1 || die "Need at least one input file plus output file";
my $output_file = pop @files;

my @input_files = map { { ObjectFormatIO::read($_) } } @files;
my %csi = StorageAllocation::calc_storage_allocation(\@input_files);
my $output_file_data = StorageAllocation::generate_output_file_data(\%csi);

# write output file
ObjectFormatIO::write($output_file, $output_file_data);
