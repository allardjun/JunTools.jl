module JunTools

"""
Design principles:
* export as little as possible, so that the user is aware that the function is coming from JunTools.

"""

export meshgrid, displog

using Dates
using Colors
using JLD2
using Makie

greet() = print("Hello from JunTools!")

os_name = Sys.KERNEL
if os_name == :Linux
    lsb = readchomp(pipeline(`lsb_release -ds`; stderr=devnull))
    ENV["GKSwstype"] = "100"
end

global base_path = ""

function get_base_path(project_name::String)
    directories = [
        "/Volumes/Carrot/Dropbox/science/projects/", # ricotta
        "/Users/jun/Dropbox/science/projects/", # nagaimo
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


# ================================================================
# Publication-quality plotting utilities
# ================================================================

"""
Convert centimeters to points for Makie figure sizing.
Uses the standard conversion: 1 cm = 72/2.54 points.

Example:
    fig = Makie.Figure(size = (JunTools.cm_to_pt(8.5), JunTools.cm_to_pt(6.0)))
"""
cm_to_pt(cm) = cm * 72 / 2.54

"""
    publication_theme(; kwargs...) -> Makie.Theme

Create a publication-quality theme for scientific journals.

# Arguments
- `fontsize::Int = 8`: Base font size in points
- `font::String = "TeX Gyre Heros"`: Font family name
- `width_cm::Float64 = 8.5`: Default figure width in cm (single column)
- `height_cm::Float64 = 6.0`: Default figure height in cm
- `journal::Symbol = :cell`: Journal preset (:cell, :nature, :pnas)

# Example
    JunTools.set_publication_theme!(journal = :nature, fontsize = 9)
"""
function publication_theme(; 
    fontsize::Int = 8,
    font::String = "TeX Gyre Heros",
    width_cm::Float64 = 8.5,
    height_cm::Float64 = 6.0,
    journal::Symbol = :cell
)
    
    # Journal-specific width settings (cm) - override width_cm if journal is specified
    if journal != :cell || width_cm == 8.5  # Only override if using default width or different journal
        journal_widths = Dict(
            :cell => (single = 8.5, double = 17.8),
            :nature => (single = 8.9, double = 18.3), 
            :pnas => (single = 8.7, double = 17.8)
        )
        
        if haskey(journal_widths, journal)
            width_cm = journal_widths[journal].single
        end
    end
    
    return Makie.Theme(
        fontsize = fontsize,
        font = font,
        Figure = (
            size = (cm_to_pt(width_cm), cm_to_pt(height_cm)),
        ),
        Axis = (
            xlabelsize = fontsize,
            ylabelsize = fontsize,
            xticklabelsize = fontsize - 1,
            yticklabelsize = fontsize - 1,
            titlesize = fontsize + 1,
            spinewidth = 1,
            xtickwidth = 1,
            ytickwidth = 1,
            xgridvisible = false,
            ygridvisible = false,
            topspinevisible = false,
            rightspinevisible = false
        ),
        Legend = (
            framevisible = false,
            labelsize = fontsize - 1,
            titlesize = fontsize
        ),
        Colorbar = (
            labelsize = fontsize - 1,
            ticklabelsize = fontsize - 1
        )
    )
end

"""
    set_publication_theme!(; kwargs...)

Set publication theme as the global default for all subsequent Makie figures.
This persists until reset with `Makie.set_theme!()` (no arguments).

# Arguments
Same as `publication_theme()`.

# Example
    using JunTools
    using CairoMakie
    CairoMakie.activate!()
    
    JunTools.set_publication_theme!(journal = :nature)
    
    # All figures now use publication theme automatically
    fig = Makie.Figure()
    ax = Makie.Axis(fig[1,1], xlabel="Time", ylabel="Signal")
"""
function set_publication_theme!(; kwargs...)
    Makie.set_theme!(publication_theme(; kwargs...))
    return nothing
end

"""
    publication_figure(; size_cm = nothing, kwargs...)

Create a Makie.Figure with publication theme applied locally (doesn't affect global theme).

# Arguments
- `size_cm::Tuple = nothing`: Override size as (width_cm, height_cm)
- `kwargs...`: Passed to Makie.Figure()

# Example
    fig = JunTools.publication_figure(size_cm = (17.8, 8.0))  # Double column
"""
function publication_figure(; size_cm = nothing, kwargs...)
    if !isnothing(size_cm)
        size_pts = (cm_to_pt(size_cm[1]), cm_to_pt(size_cm[2]))
        return Makie.Figure(size = size_pts; kwargs...)
    else
        # Use current theme default
        return Makie.Figure(; kwargs...)
    end
end

"""
    save_publication_figure(filename, fig, project_name; pt_per_unit=1, kwargs...)

Save figure to the project's plot directory with consistent settings for publication.

# Arguments
- `filename::String`: Base filename (without extension)
- `fig`: Makie figure object
- `project_name::String`: Project name for path resolution
- `pt_per_unit::Int = 1`: Ensure proper PDF scaling
- `kwargs...`: Additional arguments passed to Makie.save()

# Example
    fig = Makie.Figure()
    # ... create plot ...
    JunTools.save_publication_figure("figure1", fig, "TCRPulsing")
    # Saves to: plots/YYMMDD/figure1.pdf
"""
function save_publication_figure(filename::String, fig, project_name::String; 
                                pt_per_unit::Int = 1, 
                                format::String = "pdf",
                                kwargs...)
    
    plot_path = get_plot_path(project_name)
    full_filename = joinpath(plot_path, "$(filename).$(format)")
    
    if format == "pdf"
        Makie.save(full_filename, fig; pt_per_unit = pt_per_unit, kwargs...)
    else
        Makie.save(full_filename, fig; kwargs...)
    end
    
    return full_filename
end

"""
    journal_sizes(journal::Symbol = :cell) -> NamedTuple

Get standard figure sizes for different journals in cm.

# Example
    sizes = JunTools.journal_sizes(:nature)
    fig = JunTools.publication_figure(size_cm = (sizes.double, 10.0))
"""
function journal_sizes(journal::Symbol = :cell)
    sizes = Dict(
        :cell => (single = 8.5, double = 17.8),
        :nature => (single = 8.9, double = 18.3),
        :pnas => (single = 8.7, double = 17.8)
    )
    
    if haskey(sizes, journal)
        return (single = sizes[journal].single, double = sizes[journal].double)
    else
        @warn "Unknown journal $journal, using Cell defaults"
        return (single = 8.5, double = 17.8)
    end
end

end # module JunTools
