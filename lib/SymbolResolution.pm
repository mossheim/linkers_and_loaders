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

sub create_global_symbol_table {
    my @input_files = @{$_[0]};

    # TODO indicate which files referenced a symbol for help w undef messages?
    my %tab;
    $tab{undef_entries_key()} = {};
    $tab{multidef_entries_key()} = {};

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
                $tab{$name} = { defined => $isdef, refs => [ $fname ] };
                if ($tab{$name}{defined}) {
                    $tab{$name}{module} = $fname;
                }
            } elsif ($isdef) {
                # if already defined, move to multidefs
                if ($tab{$name}{defined}) {
                    $tab{multidef_entries_key()}{$name} = [ $tab{$name}{module}, $fname ];
                    delete $tab{$name};
                } else {
                    # exists and this is a definition, mark accordingly
                    $tab{$name}{defined} = 1;
                    $tab{$name}{module} = $fname;
                    push @{$tab{$name}{refs}}, $fname;
                }
            } else {
                push @{$tab{$name}{refs}}, $fname;
            }
        }
    }

    # move undef entries to #undef#
    for my $key (keys %tab) {
        unless (is_special_key($key) || $tab{$key}{defined}) {
            $tab{undef_entries_key()}{$key} = [ @{$tab{$key}{refs}} ];
            delete $tab{$key};
        }
    }

    # print Dumper $sym;
    return %tab;
}

sub write_global_symbol_table {
    my $output_file = $_[0];
    my %tab = %{$_[1]};

    open (OUT, ">$output_file") || die "Can't open $output_file for output: $!";

    my @sorted = sort keys %tab;
    for my $key (@sorted) {
        if (is_special_key($key)) { next; }
        print OUT "$key $tab{$key}{module}";
        for (@{$tab{$key}{refs}}) { print OUT " $_"; }
        print OUT "\n";
    }

    print OUT undef_entries_key() . "\n";

    # TODO factor out
    @sorted = sort keys %{$tab{undef_entries_key()}};
    for my $key (@sorted) {
        print OUT $key;
        for (@{$tab{undef_entries_key()}{$key}}) { print OUT " $_"; }
        print OUT "\n";
    }

    print OUT multidef_entries_key() . "\n";

    @sorted = sort keys %{$tab{multidef_entries_key()}};
    for my $key (@sorted) {
        print OUT $key;
        for (@{$tab{multidef_entries_key()}{$key}}) { print OUT " $_"; }
        print OUT "\n";
    }

    close OUT;
}

####################################################################################################
# Helper functions
####################################################################################################

sub is_special_key {
    return $_[0] eq undef_entries_key() || $_[0] eq multidef_entries_key();
}

1;
