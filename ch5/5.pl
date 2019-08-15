#!/usr/bin/env perl
# -*- perl -*-
#
# Project 5.1-5.3: Symbol resolution
use strict;
use lib 'lib';
use ObjectFormatIO;
use SymbolResolution;
use Data::Dumper qw(Dumper);

# args: last is output file, rest are input
my @files = @ARGV;
$#files >= 1 || die "Need at least one input file plus output file";
my $output_file = pop @files;

my @input_data = map { { ObjectFormatIO::read($_) } } @files;
my %global_symbol_table = SymbolResolution::create_global_symbol_table(\@input_data);
SymbolResolution::write_global_symbol_table($output_file, \%global_symbol_table);
