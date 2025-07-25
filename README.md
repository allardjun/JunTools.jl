# JunTools.jl

A collection of Julia utilities for scientific computing workflows, with a focus on publication-quality figure generation and cross-platform path management.

## Installation

Install from GitHub using either method:

**Package mode:**
```
add https://github.com/allardjun/JunTools.jl.git#main:JunTools
``` 

**Julia code:**
```julia
using Pkg
Pkg.add(url="https://github.com/allardjun/JunTools.jl.git", rev="main", subdir="JunTools")
```

## Features

### Path Management

These are specific to Jun's machines.

- `get_base_path(project_name)` - Cross-platform project directory resolution
- `get_plot_path(project_name)` - Automatic plot directory creation with timestamps
- `get_data_path(project_name)` - Automatic data directory creation with timestamps

### Publication-Quality Figure Generation

JunTools provides a complete system for creating publication-ready figures for journals with consistent sizing, fonts, and formatting.
These must be edited with a vector graphic program like Adobe Illustrator after.

#### Quick Start

```julia
using JunTools
using CairoMakie
CairoMakie.activate!()

# Set up project paths
project_name = "MyProject"
plot_path = JunTools.get_plot_path(project_name)

# Set publication theme (once per notebook/script)
JunTools.set_publication_theme!(journal = :cell, fontsize = 8)

# Create perfectly-sized figures
fig = JunTools.publication_figure()  # 8.5cm × 6.0cm automatically
ax = Makie.Axis(fig[1, 1], xlabel="Time (min)", ylabel="Signal (AU)")
lines!(ax, 1:10, rand(10))

# Save with proper PDF scaling
JunTools.save_publication_figure("my_figure", fig, plot_path)
```

#### Journal-Specific Sizing

```julia
# Automatic sizing for different journals
JunTools.set_publication_theme!(journal = :cell)     # 8.5cm single column
JunTools.set_publication_theme!(journal = :nature)   # 8.9cm single column  
JunTools.set_publication_theme!(journal = :pnas)     # 8.7cm single column

# Get standard widths
sizes = JunTools.journal_sizes(:nature)
# Returns: (single = 8.9, double = 18.3)

# Create custom-sized figures
fig_double = JunTools.publication_figure(size_cm = (sizes.double, 10.0))
```

#### Font Hierarchy

The publication theme automatically sets appropriate font sizes:
- **Axis labels:** 8pt (base font size)
- **Tick labels:** 7pt (base - 1)
- **Titles:** 9pt (base + 1)
- **Font family:** TeX Gyre Heros (scientific publication standard)

#### Saving Patterns

Two flexible saving patterns are supported:

```julia
# Pattern 1: Filename + directory (recommended)
JunTools.save_publication_figure("figure_name", fig, plot_path)
# Saves to: plot_path/figure_name.pdf

# Pattern 2: Full path (backward compatible)
full_path = joinpath(plot_path, "figure_name.pdf")
JunTools.save_publication_figure(full_path, fig)

# Multiple formats
JunTools.save_publication_figure("figure", fig, plot_path, format = "svg")
JunTools.save_publication_figure("figure", fig, plot_path, format = "png")
```

#### Complete Workflow Example

```julia
using JunTools, CairoMakie
CairoMakie.activate!()

## Project setup (once at top of notebook)
project_name = "TCRPulsing"
base_path = JunTools.get_base_path(project_name)
plot_path = JunTools.get_plot_path(project_name)
data_path = JunTools.get_data_path(project_name)

# Set theme once
JunTools.set_publication_theme!(journal = :cell)

## Create figures throughout notebook
# Single column figure
fig1 = JunTools.publication_figure()
ax1 = Makie.Axis(fig1[1, 1], xlabel="Time", ylabel="Signal")
# ... plotting code ...
JunTools.save_publication_figure("time_series", fig1, plot_path)

# Double column figure  
sizes = JunTools.journal_sizes(:cell)
fig2 = JunTools.publication_figure(size_cm = (sizes.double, 8.0))
# ... multi-panel plotting ...
JunTools.save_publication_figure("comparison", fig2, plot_path)
```

#### Key Benefits

- **Exact sizing:** Figures export at precisely specified cm dimensions
- **Consistent fonts:** Professional 8pt font hierarchy across all figures
- **Cross-platform:** Works on macOS, Linux, Windows with automatic path resolution
- **Adobe Illustrator ready:** Proper PDF scaling with `pt_per_unit=1` automatically applied
- **Journal compliance:** Preset dimensions for Cell, Nature, PNAS requirements
- **Clean API:** Minimal boilerplate, focus on content not formatting

#### Utility Functions

```julia
JunTools.cm_to_pt(8.5)  # Convert cm to pixels for Makie: 241.89

JunTools.journal_sizes(:nature)  # Get journal-specific dimensions
# Returns: (single = 8.9, double = 18.3)

# Available journals: :cell, :nature, :pnas
```

### Other Utilities

- `meshgrid(x, y)` - Create coordinate arrays from vectors
- `save_plusplus(prefix, data)` - Save with auto-incrementing filenames  
- `save_with_timestamp(prefix, data)` - Save with timestamp suffixes
- `displog(content; logfile)` - Display and log simultaneously

## Design Philosophy

JunTools follows a minimal-export philosophy. Most functions are accessed as `JunTools.function_name()` to maintain clean namespaces and make dependencies explicit.

