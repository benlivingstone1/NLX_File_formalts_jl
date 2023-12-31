using FileIO, CSV, StringEncodings

# Extract raw data from the file
data = []
# open("/Users/ben/Documents/source/vicky_data/CSC01.ncs") do file
open("/Users/ben/Documents/source/github/NLX_File_formalts_jl/RawData.nrd") do file
    remaining_bytes = 24 * 1024

    while remaining_bytes > 0
        bytes_to_read = min(remaining_bytes, 1024)  # Read in chunks of 1024 bytes
        chunk = read(file, bytes_to_read)
        append!(data, chunk)
        remaining_bytes -= bytes_to_read
    end

    # while ! eof(file)
    #     line = read(file)
    #     push!(data, line)
    # end
end

# Save vector of bytes as data
# data = data[1]

# Extract the file header (16kb) contents
header = []
for i = 1:16384
    char = [data[i]]
    if char[1] == 0xb5
        decodedChar = "μ"
    else
        decodedChar = decode(char, "UTF-8")
    end
    push!(header, decodedChar)
end

filter!(x -> x != "\0", header)
headerString = split(join(header), "\r\n")

# Convert the recorded data in readable numbers
timeStamps = []
uint32Vals = []
dataSamples = []
characters = []

for i in (16 * 1024):length(data)
    push!(characters, data[i] |> Char)
end

str = join(characters)

# Open output file in write mode 
open("output.txt", "w") do file
    # Loop over the string in chunks of 128 characters 
    for i in 1:128:length(str)
        write(file, str[i:min(i+127, end)])
        write(file, "\n")
    end
end

# i = 16385
# while i in 16385:length(data)
#     try
#         # Try decoding as Int16
#         # int16Num = reinterpret(Int16, data[i:i+1])
#         int16Num = (dataSamples[i] |> Int16) + (dataSamples[i+1] |> Int16)
#         push!(dataSamples, int16Num)
#         global i += 2  # Move the index by 2 bytes for Int16

#     catch ex_int16
#         try
#             # Try decoding as UInt32
#             uint32Num = reinterpret(UInt32, data[i:i+3])
#             push!(uint32Vals, uint32Num)
#             global i += 4  # Move index by 4 bytes for UInt32

#         catch ex_uint32
#             try
#                 # Try decoding as UInt64
#                 uint64Num = reinterpret(UInt64, data[i:i+7])
#                 push!(uint64_numbers, uint64Num)
#                 global i += 8  # Move index by 8 bytes for UInt64

#             catch ex_uint64
#                 # # If none of the above decoding attempts succeed
#                 # println("Error decoding bytes at position $i.")

#                 # Try decoding as UTF-8 characters? 
#                 try
#                     char = decode(data[i], "UTF-16")
#                     global i += 1  # Move index by one byte to recover from Error
#                     push!(characters, char)
#                 catch e 
#                     println("ERROR decoding bytes at position $i")
#                     global i += 1  # Move index by one byte to recover from Error
#                 end
                
#             end
#         end
#     end
#     println(i)
# end
