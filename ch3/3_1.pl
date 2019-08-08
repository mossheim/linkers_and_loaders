#!/usr/bin/env perl
# -*- perl -*-
#
# Project 3.1: Read and write object file
use strict;
use lib '../lib';
use ObjectFormatIO;

my $input_file = shift || die "Need an input file";
my $output_file = shift || die "Need an output file";
my %object_data = ObjectFormatIO::read_object_file($input_file);
ObjectFormatIO::write_object_file($output_file, \%object_data);
