use strict;
package ObjectFormatIO;

sub read_object_file {
    my ($input_file) = @_;
    open_input_file($input_file);
    read_link($input_file);
    my ($num_sections, $num_symbols, $num_relocs) = read_meta_sizes();
    my @sections = read_sections($num_sections);
    my @symbols = read_symbols($num_symbols);
    my @relocs = read_relocations($num_relocs);
    my @section_data = read_section_data(num_present_sections(\@sections));
    close INPUT;
    my %result = ('sections' => \@sections, 'symbols' => \@symbols, 'relocs' => \@relocs, 'section_data' => \@section_data);
    return %result;
}

sub write_object_file {
    my $output_file = $_[0];
    my %object_data = %{$_[1]};

    open_output_file($output_file);
    write_link();
    write_meta_sizes(\%object_data);
    write_sections($object_data{'sections'});
    write_symbols($object_data{'symbols'});
    write_relocations($object_data{'relocs'});
    write_section_data($object_data{'section_data'});
    close OUTPUT;
}

####################################################################################################
# Input functions
####################################################################################################

sub open_input_file {
    my ($input_file) = @_;
    open (INPUT, "$input_file") || die "Can't open input file: $!";
}

sub read_link {
    my ($input_file) = @_;
    my $link = <INPUT>;
    $link eq "LINK\n" || die "First line of $input_file is not LINK\n";
}

sub read_meta_sizes {
    my $line = <INPUT>;
    my @sizes = split(/ +/, $line);
    $#sizes < 3 || die "More than 3 meta-sizes!\n";
    for my $i (0 .. 2) { $sizes[$i] = $sizes[$i] + 0; }

    # print "# sections: $sizes[0]\n";
    # print "# symbols: $sizes[1]\n";
    # print "# relocs: $sizes[2]\n";

    return @sizes;
}

sub read_sections {
    my @result = ();
    for my $i (0 .. ($_[0]-1)) {
        my ($sec_name, $start, $size, $flags) = get_line_fields(4);
        my %map = ( 'name' => $sec_name, 'start' => $start + 0, 'size' => $size + 0, 'flags' => $flags );
        push(@result, \%map);
    }

    return @result;
}

sub read_symbols {
    my @result = ();
    for my $i (0 .. ($_[0]-1)) {
        my ($name, $value, $section, $flags) = get_line_fields(4);
        my %map = ('name' => $name, 'value' => hex($value), 'section' => $section + 0, 'flags' => $flags);
        push(@result, \%map);
    }

    return @result;
}

sub read_relocations {
    my @result = ();
    for my $i (0 .. ($_[0]-1)) {
        my ($loc, $section, $sym_id, $flags) = get_line_fields(4);
        my %map = ('loc' => hex($loc), 'section' => $section + 0, 'sym_id' => $sym_id + 0, 'flags' => $flags);
        push(@result, \%map);
    }

    return @result;
}

sub read_section_data {
    my @result = <INPUT>;
    $#result == $_[0]-1 || die "Not the right amount of section data\n";
    # print @result;
    return @result;
}

####################################################################################################
# Output functions
####################################################################################################

sub open_output_file {
    my ($output_file) = @_;
    open (OUTPUT, ">$output_file") || die "Can't open output file: $!";
}

sub write_link {
    print OUTPUT "LINK\n";
}

sub write_meta_sizes {
    my %object_data = %{$_[0]};
    my $num_sections = $#{$object_data{'sections'}} + 1;
    my $num_symbols = $#{$object_data{'symbols'}} + 1;
    my $num_relocs = $#{$object_data{'relocs'}} + 1;
    print OUTPUT "$num_sections $num_symbols $num_relocs\n";
}

sub write_sections {
    my @sections = @{$_[0]};
    for my $sec (@sections) {
        my %sec = %{$sec};
        print OUTPUT "$sec{'name'} $sec{'start'} $sec{'size'} $sec{'flags'}\n";
    }
}

sub write_symbols {
    my @symbols = @{$_[0]};
    for my $sym (@symbols) {
        my %sym = %{$sym};
        my $value = sprintf("%x", $sym{'value'});
        print OUTPUT "$sym{'name'} $value $sym{'section'} $sym{'flags'}\n";
    }
}

sub write_relocations {
    my @relocs = @{$_[0]};
    for my $reloc (@relocs) {
        my %reloc = %{$reloc};
        my $loc = sprintf("%x", $reloc{'loc'});
        print OUTPUT "$loc $reloc{'section'} $reloc{'sym_id'} $reloc{'flags'}\n";
    }
}

sub write_section_data {
    my @section_datas = @{$_[0]};
    for my $data (@section_datas) { print OUTPUT $data; }
}

####################################################################################################
# Helper functions
####################################################################################################

sub get_line_fields {
    my ($num_expected_fields) = @_;
    my $line = <INPUT>;
    chomp($line);
    my @line_fields = split(/ +/, $line);
    $#line_fields == $num_expected_fields - 1 || die "Line has incorrect number of fields: '$line'\n";
    return @line_fields
}

sub num_present_sections {
    my $i = 0;
    for my $section (@{$_[0]}) {
        my %section_info = %{$section};
        if ($section_info{'flags'} =~ /P/) {
            $i++;
        }
    }

    return $i;
}

1;
