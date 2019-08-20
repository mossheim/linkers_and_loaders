#!/usr/bin/env perl
# -*- perl -*-
#
# Project 6.1: Librarian part 1
use strict;
use lib 'lib';
use ObjectFormatIO;
use Librarian;
use Data::Dumper qw(Dumper);

# args: last is output file, rest are input
my @files = @ARGV;
$#files >= 1 || die "Need at least one input file plus output dir";
my $output_dir = pop @files;

my @input_data = map { { ObjectFormatIO::read($_) } } @files;
my %output_data = Librarian::create_dirfmt_lib(\@input_data);
Librarian::write_dirfmt_lib($output_dir, \%output_data);
