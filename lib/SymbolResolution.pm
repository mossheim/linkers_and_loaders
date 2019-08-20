use diagnostics;
use warnings;
use strict;
package SymbolResolution;
use List::Util qw(reduce max);
use Data::Dumper qw(Dumper);

# Given an array of object datas, produces a global symbol table
#
# Special fields: #undef# and #multidef# hold symbols that remain undefined or have multiple
# definitions, typically representing an error condition.

sub undef_entries_key { return '#undef#'; }
sub multidef_entries_key { return '#multidef#'; }
sub commonblock_entries_key { return '#commonblock#'; }

sub create_global_symbol_table {
    my @input_files = @{$_[0]};

    # TODO indicate which files referenced a symbol for help w undef messages?
    my %tab;
    $tab{undef_entries_key()} = {};
    $tab{multidef_entries_key()} = {};
    $tab{commonblock_entries_key()} = {};

    for my $file_data (@input_files) {
        my $fname = $file_data->{filename};
        for my $sym (@{$file_data->{symbols}}) {
            # print Dumper $sym;
            my $name = $sym->{name};
            my $isdef = ($sym->{flags} eq 'D');
            my $ismultidef = exists $tab{multidef_entries_key()}{$name};

            # if already marked as multidef, add to list of multidefs
            if ($isdef and $ismultidef) {
                push(@{$tab{multidef_entries_key()}{$name}}, $fname);
            } elsif (not exists $tab{$name}) {
                # create entry
                $tab{$name} = {
                    defined => $isdef,
                    max_value => $sym->{value},
                    refs => [ $fname ],
                };
                if ($tab{$name}{defined}) {
                    $tab{$name}{module} = $fname;
                    $tab{$name}{value} = $sym->{value};
                    $tab{$name}{section} = $sym->{section};
                }
            } elsif ($isdef) {
                # if already defined, move to multidefs
                if ($tab{$name}{defined}) {
                    $tab{multidef_entries_key()}{$name} = [ $tab{$name}{module}, $fname ];
                    delete $tab{$name};
                } else {
                    # exists and this is a definition, mark accordingly
                    # no need to record maxvalue
                    $tab{$name}{defined} = 1;
                    $tab{$name}{module} = $fname;
                    push @{$tab{$name}{refs}}, $fname;
                }
            } else {
                $tab{$name}{max_value} = max($tab{$name}{max_value}, $sym->{value});
                push @{$tab{$name}{refs}}, $fname;
            }
        }
    }

    # move undef entries to #undef#, common to #commonblock#
    for my $key (keys %tab) {
        unless (is_special_key($key) || $tab{$key}{defined}) {
            if ($tab{$key}{max_value} > 0) {
                $tab{commonblock_entries_key()}{$key} = {
                    refs => $tab{$key}{refs},
                    size => $tab{$key}{max_value},
                };
            } else {
                $tab{undef_entries_key()}{$key} = [ @{$tab{$key}{refs}} ];
            }
            delete $tab{$key};
        }
    }

    # print Dumper $sym;
    return %tab;
}

# resolves symbol values to the section in which they are defined, after final storage allocation.
sub resolve_symbol_values {
    my @input_data = @{$_[0]};
    my %tab = %{$_[1]};
    my @output_sections = @{$_[2]};

    my %data_by_filename = map { $_->{filename} => $_ } @input_data;

    for my $key (keys %tab) {
        if (is_special_key($key)) { next; }
        my $module_name = $tab{$key}{module};
        my $section_index = $tab{$key}{section} - 1;
        my $section_offset = $data_by_filename{$module_name}{sections}[$section_index]{start};

        $tab{$key}{value} += $section_offset;
    }

    my @bss_secs = grep { $_->{name} eq '.bss' } @output_sections;
    my $maybe_bss = shift @bss_secs;
    if (defined $maybe_bss) {
        # print Dumper $maybe_bss;
        my $com_block_end = $maybe_bss->{start} + $maybe_bss->{size};
        my $com_block_start = $maybe_bss->{start} + $maybe_bss->{size} - $maybe_bss->{tcbs};
        my @sorted = sort keys %{$tab{commonblock_entries_key()}};
        my %com_blocks = %{$tab{commonblock_entries_key()}};
        for my $key (@sorted) {
            $com_blocks{$key}{value} = $com_block_start;
            # print Dumper $com_blocks{$key};
            $com_block_start += $com_blocks{$key}{size};
        }
    }
}

# checks that the global symbol table is in good condition -- no multi-defined or undefined symbols
# prints warnings, returns bool to indicate success/fail
sub validate_global_symbol_table {
    # TODO
    # TODO test this
}

sub write_global_symbol_table {
    my $output_file = $_[0];
    my %tab = %{$_[1]};

    open (OUT, ">$output_file") || die "Can't open $output_file for output: $!";

    my @sorted = sort keys %tab;
    for my $key (@sorted) {
        if (is_special_key($key)) { next; }
        print OUT "$key $tab{$key}{value} $tab{$key}{module}";
        print_space_sep_list($tab{$key}{refs});
        print OUT "\n";
    }

    print_common_block_section($tab{commonblock_entries_key()});
    print_section_with_header(\%tab, undef_entries_key());
    print_section_with_header(\%tab, multidef_entries_key());
    close OUT;
}

####################################################################################################
# Helper functions
####################################################################################################

sub is_special_key {
    return $_[0] eq undef_entries_key() || $_[0] eq multidef_entries_key() || $_[0] eq commonblock_entries_key();
}

sub print_section_with_header {
    my ($tab, $sec_key) = @_;
    my $num_entries = %{$tab->{$sec_key}};
    if ($num_entries == 0) { return; }

    print OUT "$sec_key\n";
    my @sorted = sort keys %{$tab->{$sec_key}};
    for my $key (@sorted) {
        print OUT $key;
        print_space_sep_list($tab->{$sec_key}{$key});
        print OUT "\n";
    }
}

sub print_common_block_section {
    my %com_blocks = %{$_[0]};
    my @sorted = sort keys %com_blocks;

    if ($#sorted == -1) { return; }

    print OUT commonblock_entries_key() . "\n";
    for my $key (@sorted) {
        print OUT "$key $com_blocks{$key}{value}";
        print_space_sep_list($com_blocks{$key}{refs});
        print OUT "\n";
    }
}

sub print_space_sep_list {
    for (@{$_[0]}) { print OUT " $_"; }
}

1;
