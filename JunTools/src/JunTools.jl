module JunTools

"""
Design principles:
* export as little as possible, so that the user is aware that the function is coming from JunTools.

"""

export meshgrid, displog

using Dates
using Colors
using JLD2

greet() = print("Hello from JunTools!")

os_name = Sys.KERNEL
if os_name == :Linux
    lsb = readchomp(pipeline(`lsb_release -ds`; stderr=devnull))
    ENV["GKSwstype"] = "100"
end

global base_path = ""

function get_base_path(project_name::String)
    directories = [
        "/Users/jun/Dropbox/science/projects/", # nagaimo
        "/Volumes/Carrot/Dropbox/science/projects/", # ricotta
        "/home/ubuntu/science/projects/", # aws
        "/pub/jallard/science/projects/", # hpc3
        ".", # if none of the above are found, default to the current directory
    ]

    global base_path = ""

    # Loop through the directory names
    for dir in directories
        global base_path
        if isdir(dir)
            # If the directory exists, assign its name to the variable
            base_path = dir
            # Exit the loop
            break
        end
    end
    return joinpath(base_path, project_name)
end

function get_plot_path(project_name::String; date=nothing)
    if isnothing(date)
        date = Dates.format(now(), "yymmdd")
    end

    data_path = joinpath(get_base_path(project_name), "plots", date)
    if !isdir(data_path)
        mkpath(data_path)
    end
    return data_path
end

function get_data_path(project_name::String; date=nothing)
    if isnothing(date)
        date = Dates.format(now(), "yymmdd")
    end

    data_path = joinpath(get_base_path(project_name), "data", date)
    if !isdir(data_path)
        mkpath(data_path)
    end
    return data_path
end

colors = [Colors.RGB(0.6, 0.8 - i * 0.1, 1.0) for i in 0:7]

# Helper function to create a meshgrid (since Julia doesn't have a built-in function like Python's numpy.meshgrid)
function meshgrid(x, y)
    return repeat(reshape(x, 1, :), length(y), 1), repeat(reshape(y, :, 1), 1, length(x))
end

# #######

function displog(content; logfile=nothing)
    # Display in REPL
    display(content)

    # Write to file
    if !isnothing(logfile)
        open(logfile, "a") do file
            println(file, content)
        end
    end
end

# #######

"""
    save_with_increment(data, prefix::String; start_num::Int=1) -> String

Save data to a JLD2 file with an auto-incrementing suffix.
Returns the filename that was actually used.

Example:
    # If "data.jld2" exists, saves to "data_1.jld2"
    filename = save_with_increment(mydata, "data")
"""
function save_plusplus(prefix::String, data; start_num::Int=1)
    base_filename = prefix * ".jld2"
    
    # If base filename doesn't exist, use it
    if !isfile(base_filename)
        @save base_filename data
        return base_filename
    end
    
    # Try incrementing numbers until we find an unused filename
    counter = start_num
    while true
        filename = "$(prefix)_$(counter).jld2"
        if !isfile(filename)
            @save filename data
            return filename
        end
        counter += 1
    end
end

"""
    save_with_timestamp(data, prefix::String) -> String

Save data to a JLD2 file with a timestamp suffix.
Returns the filename that was actually used.

Example:
    # Saves to something like "data_2024-10-27_1435.jld2"
    filename = save_with_timestamp(mydata, "data")
"""
function save_with_timestamp(prefix::String, data)
    # Format: YYYY-MM-DD_HHMM
    timestamp = Dates.format(now(), "yyyy-mm-dd_HHMM")
    filename = "$(prefix)_$(timestamp).jld2"
    
    @save filename data
    return filename
end


end # module JunTools
