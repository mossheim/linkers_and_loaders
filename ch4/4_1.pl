#!/usr/bin/env perl
# -*- perl -*-
#
# Project 4.1: Storage allocation
use strict;
use lib 'lib';
use ObjectFormatIO;
use StorageAllocation;
use Data::Dumper qw(Dumper);

# args: last is output file, rest are input
my @files = @ARGV;
$#files >= 1 || die "Need at least one input file plus output file";
my $output_file = pop @files;

my @input_files = map { { ObjectFormatIO::read($_) } } @files;
my %output_file_data = StorageAllocation::calc_storage_allocation(\@input_files);
ObjectFormatIO::write($output_file, \%output_file_data);
