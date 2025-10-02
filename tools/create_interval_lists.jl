# This script defines functions and uses them to create separate lists
# of intervals to submit to gatk. This is done so that the large contigs
# can run alone and the smaller contigs will be put into groups roughly
# the size of the large contigs as a way of efficiently paralellizing gatk.

# Clean file to only have entries about contigs, not other data

function clean_dict_file(dict_file)

    contigs = fill(false, length(dict_file))

    for (index, line) in pairs(dict_file)
        if startswith(line, "@SQ")
            contigs[index] = true
        end
    end

    dict_with_only_contigs = dict_file[contigs]

    return dict_with_only_contigs

end

# Extract contig name from each line  

function contig_names_from_dict(dict_file)

    dict_file = clean_dict_file(dict_file)

    contig_names = Vector{String}(undef, length(dict_file))

    for (index, line) in pairs(dict_file)
        if startswith(line, "@SQ")
            new_name = split(split(line, "\t")[2], ":")[2]
            contig_names[index] = new_name
        end
    end

    return contig_names

end

# Extract contig length from each line

function contig_lengths_from_dict(dict_file)

    dict_file = clean_dict_file(dict_file)

    contig_lengths = Vector{Int}(undef, length(dict_file))

    for (index, line) in pairs(dict_file)
        if startswith(line, "@SQ")
            new_length = split(split(line, "\t")[3], ":")[2]
            contig_lengths[index] = parse(Int, new_length)
        end
    end

    return contig_lengths

end

# Extract contig names and lengths at once from the dict as a tuple

function contig_names_and_lengths_from_dict(dict_file)

    dict_file = clean_dict_file(dict_file)

    contig_names = Vector{String}(undef, length(dict_file))
    contig_lengths = Vector{Int}(undef, length(dict_file))

    for (index, line) in pairs(dict_file)
        if startswith(line, "@SQ")
            contig_names[index] = split(split(line, "\t")[2], ":")[2]
            contig_lengths[index] = parse(Int, split(split(line, "\t")[3], ":")[2])
        end
    end

    return contig_names, contig_lengths

end

# Sort the contig names, keeping them with lengths and returning as a tuple
function sort_contigs_desc_by_length(contig_names, contig_lengths)
    permutation = sortperm(contig_lengths, rev=true)
    new_contig_names = contig_names[permutation]
    new_contig_lengths = contig_lengths[permutation]
    return new_contig_names, new_contig_lengths
end

# Make interval name from name and length
function interval_from_contig(contig_name, contig_length)
    interval = contig_name * ":" * "1" * "-" * string(contig_length)
    return interval
end

# Sort contigs into bins the size of the largest chromosome
function bins_from_lengths(sorted_contig_lengths)

    # Which bin each contig is sorted into (0 is not a real bin)
    bin_addresses = fill(0, length(sorted_contig_lengths))

    # The max bin size allowed is the size of the largest chromosome
    bin_max_size = sorted_contig_lengths[1]

    # Keeping track of how many bins were assigned
    total_bin_count = 0

    # Keeping track of bin sums
    bin_sums = Vector{Int}()

    # Actual sorting
    for (contig_index, length) in pairs(sorted_contig_lengths)

        placed = false

        for i in 1:total_bin_count

            if ( bin_sums[i] + length ) <= bin_max_size
                bin_addresses[contig_index] = i 
                placed = true
                bin_sums[i] = bin_sums[i] + length
                break # Stop loop over bins if item fits in this bin
            end

        end

        # Make a new bin for things that weren't placed in an existing one
        if placed == false
    
            # Add a bin for the item
            total_bin_count = total_bin_count + 1
            # The most recent bin is used for the item
            bin_addresses[contig_index] = total_bin_count
            push!(bin_sums, length)

        end

    end

    return bin_addresses

end

# Bigger function to get intervals from contigs
function intervals_batched_from_dict(dict_file, outdir)

    names, lengths =  contig_names_and_lengths_from_dict(dict_file)

    names, lengths = sort_contigs_desc_by_length(names, lengths)

    bin_addresses = bins_from_lengths(lengths)

    # Make sure output directory exists  
    mkpath(outdir) 
    
    	# Make sure files are empty and write to manifest of interval lists
	
	manifestpath = joinpath(outdir, "lists_manifest.txt")
	manifestfile = open(manifestpath, "a")

        for i in 1:maximum(bin_addresses)
            
	    txtfilename = "intervals_$(bin_addresses[i]).list"
            txtfilepath = joinpath(outdir, txtfilename)
            txtfile = open(txtfilepath, "w")
            close(txtfile) # Just opening in write mode and immediately closing to clear
	    write(manifestfile, "$(txtfilename)\n")

        end

	close(manifestfile)

        # Append intervals to correct file according to their bin address
        for (index, name) in pairs(names)

            txtfilepath = joinpath(outdir, "intervals_$(bin_addresses[index]).list")
            txtfile = open(txtfilepath, "a")
            write(txtfile, "$(interval_from_contig(name, lengths[index]))\n")
            close(txtfile)

        end 

end

# This is where the script actually running the functions starts!!

# Handle arguments from bash
if length(ARGS) > 0
        dict_file_path = ARGS[1]
        output_dir_path = ARGS[2] 
        println("Received dict file path: $(dict_file_path)")
        println("Received output file path: $(output_dir_path)")
    else
        println("No arguments received from shell.")
    end 

# Read dict file
dict_file = readlines(dict_file_path)

# Run intervals function to create interval list files (It calls
# the other functions.)
intervals_batched_from_dict(dict_file, output_dir_path)

