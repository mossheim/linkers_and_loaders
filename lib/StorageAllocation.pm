use diagnostics;
use warnings;
use strict;
package StorageAllocation;
use List::Util qw(reduce max);

# Given an array of object datas, calculates combined sizes of segments.
# Also implements UNIX-style common blocks.
# Also updates the sections in the input with new locations after allocation.
#
# Output format:
#
# csi :: {
#     [ name w/o period => section_info ]
# }
#
# where
#
# section_info :: { start, size, flags (, end, accum, tcbs) }
#
# end only for text and data
# accum is a temp field
# tcbs only for bss

sub calc_storage_allocation {
    my @input_files = @{$_[0]};

    # see above for format of csi
    my %csi = calc_combined_sizes(\@input_files);
    calc_section_layout(\%csi, total_common_block_size(\@input_files));
    assign_new_section_starts(\@input_files, \%csi);
    return %csi;
}

# turn combined segment info into data that can be written via ObjectFormatIO::write
sub generate_output_file_data {
    my %csi = %{$_[0]};
    return {
        'sections' => [ $csi{text}, $csi{data}, $csi{bss} ],
        'symbols' => [],
        'relocs' => [],
        'section_data' => [],
    };
}

####################################################################################################
# Helper functions
####################################################################################################

# returns a partial %csi map -- just map from name=>size
sub calc_combined_sizes {
    my @input_files = @{$_[0]};

    # group all .text, .data, .bss
    my @section_names = ('.text', '.bss', '.data');
    my %sections = map { $_ => [ get_sections_from_files(\@input_files, $_) ] } @section_names;

    # calculate combined sizes
    # 'csi' = combined section info
    my %csi = map { substr($_, 1) => {'name'=>$_} } @section_names;
    for my $name (@section_names) {
        $csi{substr($name, 1)}{size} = total_section_length(\%sections, $name)
    }

    return %csi;
}

# assigns section starts, ends, flags, and applies total common block size
sub calc_section_layout {
    my %csi = %{$_[0]};
    my $tcbs = $_[1];

    # text starts at 0x1000
    $csi{text}{start} = 0x1000;
    $csi{text}{end} = $csi{text}{start} + $csi{text}{size};

    # data starts at next multiple of 1000 rounded up from end of text
    $csi{data}{start} = next_multiple_of_power_of_two($csi{text}{end}, 12);
    $csi{data}{end} = $csi{data}{start} + $csi{data}{size};

    # bss starts at next multiple of 4 rounded up from end of data
    $csi{bss}{start} = next_multiple_of_power_of_two($csi{data}{end}, 2);
    # don't need to compute end

    # additional fields
    $csi{text}{flags} = 'RP';
    $csi{data}{flags} = 'RWP';
    $csi{bss}{flags} = 'RW';
    $csi{bss}{tcbs} = $tcbs;
    $csi{bss}{size} += $csi{bss}{tcbs};
}

sub get_sections_from_files {
    my @files = @{$_[0]};
    my $name = $_[1];
    return map { get_sections_from_file($_, $name) } @files;
}

sub get_sections_from_file {
    my %data = %{$_[0]};
    my $name = $_[1];
    my @sects = @{$data{sections}};
    my @filtered = grep { $_->{name} eq $name } @sects;
    return @filtered;
}

sub next_multiple_of_power_of_two {
    my ($val, $pow) = @_;
    my $one_less = (1 << $pow) - 1;
    return (($val + $one_less) >> $pow) << $pow;
}

# length of all sections with given name in $sections
sub total_section_length {
    my ($sections, $name) = @_;
    return reduce { $a + $b->{size}; } 0, @{$sections->{$name}};
}

# find sum of common blocks in input files
# common blocks are undefined symbols with nonzero values; size is eq to value
# take the common block size to be the largest value encountered for that symbol name
sub total_common_block_size {
    my @input_files = @{$_[0]};
    my %common_blocks;
    for my $file (@input_files) {
        for my $symbol (@{$file->{symbols}}) {
            if (is_common_block($symbol)) {
                my $name = $symbol->{name};
                my $size = $symbol->{value};
                if (not exists $common_blocks{$name}) { $common_blocks{$name} = 0; }
                $common_blocks{$name} = max($common_blocks{$name}, $size);
            }
        }
    }

    return reduce { $a + $common_blocks{$b} } 0, (keys %common_blocks);
}

sub is_common_block {
    my ($symbol) = @_;
    return ($symbol->{value} > 0) && ($symbol->{flags} =~ 'U');
}

sub assign_new_section_starts {
    my @input_files = @{$_[0]};
    my %csi = %{$_[1]};

    for my $file (@input_files) {
        for my $file_sec (@{$file->{sections}}) {
            # name minus dot
            my $nmd = substr($file_sec->{name}, 1);
            # accum is a temporary field to accumulate sizes
            if (not exists $csi{$nmd}{accum}) { $csi{$nmd}{accum} = 0; };
            $file_sec->{start} = $csi{$nmd}{start} + $csi{$nmd}{accum};
            $csi{$nmd}{accum} += $file_sec->{size};
        }
    }
}

1;
