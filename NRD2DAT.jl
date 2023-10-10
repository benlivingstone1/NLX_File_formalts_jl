# Not finished **********************************


using FileIO, CSV, StringEncodings, DataFrames, CSV, Plots, Statistics

file = "/Users/ben/Documents/source/github/NLX_File_formalts_jl/RawData.nrd"

const STX_target = 2048  # Identifies new start 
const HEADER_SIZE = (16 * 1024)  # 16kb header 
const RECORD_SIZE = 456
const NUM_CHANNELS = 96  # reading data from 63 channels 


function crc(buff::Vector{UInt8}, nChannelsTotal::Int)
    recordHeaderFooterSize = 18  # in Int32
    recordFieldCount = recordHeaderFooterSize + nChannelsTotal
    crcValue = Int32(0)
    for fieldIndex in 0:(recordFieldCount-1)
        currentField = reinterpret(Int32, buff[(fieldIndex*4+1):(fieldIndex*4+4)])[1]
        crcValue ⊻= currentField
    end
    return crcValue
end


# # Make output directory
# parent_dir = dirname(file)
# output_dir = join([parent_dir, "/", "output_data"])
# println(output_dir)

# # Check it output directory exists 
# if ! isdir(output_dir)
#     mkdir(output_dir)
# end

# output_file = join([output_dir, "/", "RawData.csv"])

# Create Dataframe to store data 
column_titles = ["Time_Stamp", "STX_value", "Packet_ID", "Packet_Size", "CRC_value"]
for i in 1:NUM_CHANNELS
    push!(column_titles, (i |> string))
end

df = DataFrame(; (Symbol(name) => [] for name in column_titles)...)

# CSV.write(output_file, df) 

recorded_data = []

open(file, "r") do f
    # Seek the end of the header 
    seek(f, HEADER_SIZE)

    i = 1
    while ! eof(f) && i < 1000
        # Get starting position
        start_pos = position(f) 
        # First Int32 after header
        STX = read(f, Int32)
        # println("STX = $STX")

        # Find next valid start sequence
        if STX != STX_target
            println("Could Not Find Starting Symbol. Trying again...")
            continue
        end

        packet_id = read(f, Int32)
        packet_size = read(f, Int32)

        # println("Start symbol = $STX , Packet ID = $packet_id , Packet size = $packet_size")

        # Position to return to after CRC 
        return_pos = position(f) 

        # Read full packet 
        seek(f, start_pos) 
        packet = read(f, 456)
        crc_value = crc(packet, NUM_CHANNELS)

        # println(crc_value)

        seek(f, return_pos)

        # Decode the timestamps CONFIRM THIS IS RIGHT
        timestamp = read(f, UInt32)
        timestamp << 32
        timestampLow = read(f, UInt32)
        timestamp += timestampLow

        # println(timestamp)

        status = read(f, Int32)
        parallel_input_port = read(f, Int32)

        events = []
        for i in 1:10
            push!(events, read(f, Int32))
        end
        
        channel_data = []
        for i in 1:NUM_CHANNELS
            push!(channel_data, read(f, Int32))
        end

        push!(recorded_data, channel_data)

        # println(channel_data)
        
        footer = read(f, Int32) 

        # Create DataFrame row  
        row = [Int32(timestamp), STX, packet_id, packet_size, crc_value]
        for i = eachindex(channel_data)
            append!(row, Int32(channel_data[i])) 
        end

        row_df = DataFrame(reshape(row, 1, length(row)), :auto) 
        # for i in eachcol(df)
        #     i = Int32.(i)
        # end

        push!(df, row)

        # # Add row to CSV file 
        # CSV.write(output_file, Tables.rowtable(row_df), header=false, append=true)

        i +=1 
    end

end

# Transform 'recorded_data' into matrix 
data_matrix = hcat(recorded_data...)'
# Find all channels in the matrix that do not change between samples 
channel_variance = [var(data_matrix[:, j]) for j in axes(data_matrix, 2)]
constant_columns = findall(x -> x == 0, channel_variance)

# Plot Variance 
x = collect(1:length(channel_variance))
scatter(
    x[1:64], 
    channel_variance[1:63], 
    label = "target 63 channels?",
    title = "Channel Variance",
    xlabel = "Channel #",
    ylabel = "Variance"
)
    
scatter!(
    x[65:end], 
    channel_variance[64:end], 
    color = :red, 
    label = "Junk 33 channels?"
)