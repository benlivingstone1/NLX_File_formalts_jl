using FileIO, CSV, DataFrames, CSV, Statistics
using InteractiveViz
using GLMakie

# Path to raw data CSV file
file = "/Users/ben/Documents/source/github/NLX_File_formalts_jl/output_data/RawData.csv"

# Read row of file 
# Normalize names is required since the channel names are [1, 2, 3,..., N]. This will
# Rename the columns to ["_1", "_2", ..., "_N"]
data = CSV.File(file, normalizenames=true) 

channel1 = data._1
i32channel1 = channel1 .|> Int32

# # Plot channel 1 data 
# # This works and is interactive but its fuckin biiiiiiiggggg man
# # Slow af while taking up like 10GB RAM.
# x = collect(1:length(channel1))
# viz_plot = iplot(x, channel1)
# display(viz_plot)

# keep channels 1-63 only 
open("/Users/ben/Documents/source/github/NLX_File_formalts_jl/output_data/RawData.dat", "w") do f
    for j in eachindex(data)
        # rowbytes = []
        if (j % 1_000_000) == 0
            println("Finished writing $j / 19_000_000 records")
        end
        
        for i in eachindex(data.names)
            if 6 <= i <= 68
                bytes = reinterpret(UInt8, [(data[j][i]) |> Int32])
                bytes = [x for x in bytes]
                write(f, bytes...)
            end
        end
    end
end
# Convert number to Int32 

# Add bytes to DAT file 

# # Decode file
# decoded = []
# open("/Users/ben/Documents/source/github/NLX_File_formalts_jl/output_data/RawData.dat", "r") do f
#     while ! eof(f)
#         push!(data, read(f, Int32))
#     end

# end