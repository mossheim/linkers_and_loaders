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

# In: array of object files
# Out: { modules => original array, gst => global symbol table }
sub create_dirfmt_lib {
    my ($objects) = @_;
    my %gst = SymbolResolution::create_global_symbol_table($objects);
    SymbolResolution::validate_global_symbol_table(\%gst) || die "Issue in symbol table";
    return (modules => $objects, gst => \%gst);
}

# Produces a 'dirfmt' library using output data at the given output dir.
# The format is as follows:
# - each library is a directory
# - there is one file per object file
# - there is one hard link per exported symbol; each links to the object file which defines it
#
# In: output dir, output data { modules => original array, gst => global symbol table }
sub write_dirfmt_lib {
    my ($output_dir, $output_data) = @_;
    my $modules = $output_data->{modules};
    my $gst = $output_data->{gst};

    `mkdir $output_dir` || die "Could not mkdir $output_dir";
    for (@$modules) {
        my $module_file = $output_dir . '/' . $_->{filename};
        ObjectFormatIO::write($module_file, $_);
    }

    # TODO
}

1;
