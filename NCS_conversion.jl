using FileIO, CSV, StringEncodings, Plots

# Extract raw data from the file
data = []
open("C:/Users/ben/Downloads/CSC01.ncs") do file
    while ! eof(file)
        line = read(file)
        push!(data, line)
    end
end

# Save vector of bytes as data
data = data[1]

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

i = 16385
while i in 16385:length(data)
    try
        # Try decoding as Int16
        int16Num = reinterpret(Int16, data[i:i+1])
        push!(dataSamples, int16Num)
       i += 2  # Move the index by 2 bytes for Int16

    catch ex_int16
        try
            # Try decoding as UInt32
            uint32Num = reinterpret(UInt32, data[i:i+3])
            push!(uint32Vals, uint32Num)
           i += 4  # Move index by 4 bytes for UInt32

        catch ex_uint32
            try
                # Try decoding as UInt64
                uint64Num = reinterpret(UInt64, data[i:i+7])
                push!(uint64_numbers, uint64Num)
                i += 8  # Move index by 8 bytes for UInt64

            catch ex_uint64
                # If none of the above decoding attempts succeed
                println("Error decoding bytes at position $i.")
                i += 1  # Move index by one byte to recover from Error
            end
        end
    end
end

x = collect(1:length(dataSamples))
plot(x[1:10000], dataSamples[1:10000])