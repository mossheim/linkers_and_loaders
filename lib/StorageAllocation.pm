use diagnostics;
use warnings;
use strict;
package StorageAllocation;
use List::Util qw(reduce max);
use Data::Dumper qw(Dumper);

# Given an array of object datas, calculates combined sizes of segments.
# Also implements UNIX-style common blocks.
# Also updates the sections in the input with new locations after allocation.
#
# Output format 'combined section info':
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
    my @csi = StorageAllocation::calc_combined_section_info(\@input_files);
    return StorageAllocation::generate_output_file_data(\@csi);
}

sub calc_combined_section_info {
    my @input_files = @{$_[0]};

    # see above for format of csi
    my @csi = calc_combined_sizes(\@input_files);
    calc_section_layout(\@csi, total_common_block_size(\@input_files));
    assign_new_section_starts(\@input_files, \@csi);

    return @csi;
}

# turn combined segment info into data that can be written via ObjectFormatIO::write
sub generate_output_file_data {
    return (
        'sections' => $_[0],
        'symbols' => [],
        'relocs' => [],
        'section_data' => [],
    );
}

####################################################################################################
# Helper functions
####################################################################################################

# returns a partial %csi map -- just map from name=>size
sub calc_combined_sizes {
    my @input_files = @{$_[0]};

    my @all_section_names = get_all_section_names(\@input_files);
    my %name_to_sections = map { $_ => [ get_sections_from_files(\@input_files, $_) ] } @all_section_names;

    # calculate combined sizes
    # 'csi' = combined section info
    my @csi = map { {
            name => $_,
            size => total_section_length($name_to_sections{$_}),
            flags => validate_section_flags($name_to_sections{$_}),
        } } @all_section_names;

    sub flags_to_int {
        my ($flags) = @_;
        return $flags eq 'RP' ? 1 :
            $flags eq 'RWP' ? 2 :
            $flags eq 'RW' ? 3 : warn "Unsupported flag type $flags";
    }

    sub cmp_name {
        my ($l, $r) = @_;
        return $l eq '.bss' ? 1 :
            $r eq '.bss' ? -1 :
            $l cmp $r;
    }

    return sort {
        flags_to_int($a->{flags}) cmp flags_to_int($b->{flags}) || cmp_name($a->{name}, $b->{name})
    } @csi;
}

# all unique section names
sub get_all_section_names {
    my @input_files = @{$_[0]};
    my @names = map { map { $_->{name} } @{$_->{sections}} } @input_files;
    my %names_map = map { $_, 1 } @names;
    return keys %names_map;
}

# all unique section names
sub validate_section_flags {
    my @sections = @{$_[0]};
    my $flags = $sections[0]->{flags};
    my $i = 0;
    for my $section (@sections) {
        $section->{flags} eq $flags ||
            warn "validate_section_flags: flags in section $i ($section->{flags}) do not match "
                . "those in section 1 ($flags)\n";
        $i++;
    }

    return $flags;
}

# assigns section starts, ends, flags, and applies total common block size
sub calc_section_layout {
    my ($csi, $tcbs) = @_;
    my $storage_ptr = 0x1000;

    sub update_storage {
        my ($ptr, $flags, $csi) = @_;
        for my $sec (grep { $_->{flags} eq $flags } @$csi) {
            $sec->{start} = $ptr;
            $ptr += $sec->{size};
        }

        return $ptr;
    }

    $storage_ptr = update_storage($storage_ptr, 'RP', $csi);

    # data starts at next multiple of 1000 rounded up from end of text
    $storage_ptr = next_multiple_of_power_of_two($storage_ptr, 12);
    $storage_ptr = update_storage($storage_ptr, 'RWP', $csi);

    # bss starts at next multiple of 4 rounded up from end of data
    $storage_ptr = next_multiple_of_power_of_two($storage_ptr, 2);
    $storage_ptr = update_storage($storage_ptr, 'RW', $csi);

    for (@$csi) {
        if ($_->{name} eq '.bss') {
            $_->{size} += $tcbs;
            $_->{tcbs} = $tcbs;
            return;
        }
    }

    if ($tcbs) {
        push(@$csi, {
            name => '.bss',
            size => $tcbs,
            tcbs => $tcbs,
            flags => 'RW',
            start => $storage_ptr,
        });
    }
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
    return reduce { $a + $b->{size} } 0, @{$_[0]};
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
    my @csi = @{$_[1]};
    my %csi = map { $_->{name} => $_ } @csi;

    for my $file (@input_files) {
        for my $file_sec (@{$file->{sections}}) {
            # name minus dot
            my $name = $file_sec->{name};
            # accum is a temporary field to accumulate sizes
            if (not exists $csi{$name}{accum}) { $csi{$name}{accum} = 0; };
            $file_sec->{start} = $csi{$name}{start} + $csi{$name}{accum};
            $csi{$name}{accum} += $file_sec->{size};
        }
    }
}

1;
