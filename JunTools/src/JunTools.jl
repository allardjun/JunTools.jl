module JunTools

export greet, get_base_path, plot_path, data_path, colors, meshgrid, displog

using Dates
using Colors

greet() = print("Hello from JunTools!")

os_name = Sys.KERNEL
if os_name == :Linux
    lsb = readchomp(pipeline(`lsb_release -ds`, stderr=devnull))
    ENV["GKSwstype"] = "100"
end

global base_path = ""

function get_base_path()



    directories = [
        "/Volumes/Carrot/Dropbox/science/projects/", # ricotta
        "/Users/jun/Dropbox/science/projects/", # nagaimo
        "/home/ubuntu/science/projects/", # aws
        "/pub/jallard/science/projects/", # hpc3
        ".", # if none of the above are found, default to the current directory
    ]


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
    return base_path
end

function plot_path(project_name::String)

    today_date = Dates.format(now(), "yymmdd")

    plot_path = joinpath(get_base_path(), project_name, "plots", today_date)
    if !isdir(plot_path)
        mkdir(plot_path)
    end
    return plot_path
end

function data_path(project_name::String; today_date=nothing)

    if isnothing(today_date)
        today_date = Dates.format(now(), "yymmdd")
    end

    data_path = joinpath(get_base_path(), project_name, "data", today_date)
    if !isdir(data_path)
        mkdir(data_path)
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


end # module JunTools
