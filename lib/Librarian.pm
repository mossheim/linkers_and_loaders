use diagnostics;
use warnings;
use strict;
package Librarian;
use SymbolResolution;
use List::Util qw(reduce max);
use Data::Dumper qw(Dumper);

# Librarian utilities
#
# Two formats are supported (Project 6):
# - 'dirfmt' - IBM-like directory format
# - 'filfmt' - single-file format

sub create_dirfmt_lib {
    my ($objects) = @_;
    my %gst = SymbolResolution::create_global_symbol_table($objects);
    SymbolResolution::validate_global_symbol_table(\%gst);
    # TODO
    return ();
}

# Produces a 'dirfmt' library using output data at the given output dir.
# The format is as follows:
# - each library is a directory
# - there is one file per object file
# - there is one hard link per exported symbol; each links to the object file which defines it
sub write_dirfmt_lib {
    my ($output_dir, $output_data) = @_;
    # TODO
}

1;
