# Comprehensive test suite for JunTools publication plotting functionality
using JunTools
using CairoMakie
CairoMakie.activate!()

println("JunTools Publication Plotting Test Suite")
println("="^50)

# Test data
x = 0:0.1:10
project_name = "JunTools_test"

## Test 1: Theme setup and basic functionality
println("\n1. Testing theme setup...")
JunTools.set_publication_theme!(journal = :cell, fontsize = 8)

# Verify conversion function
cm_val = 8.5
pts_val = JunTools.cm_to_pt(cm_val)
expected = 8.5 * 72 / 2.54
println("   cm_to_pt($(cm_val)) = $(round(pts_val, digits=2)) pixels")
println("   Expected: $(round(expected, digits=2)) pixels")
@assert abs(pts_val - expected) < 0.01 "Conversion function failed"

# Test journal sizes
sizes = JunTools.journal_sizes(:cell)
println("   Cell sizes: single=$(sizes.single)cm, double=$(sizes.double)cm")
@assert sizes.single == 8.5 "Cell single width incorrect"
@assert sizes.double == 17.8 "Cell double width incorrect"

println("   ✓ Theme and utilities working correctly")

## Test 2: Figure creation with explicit sizing
println("\n2. Testing figure creation...")

# Test publication_figure() with defaults
fig1 = JunTools.publication_figure()
expected_size = (JunTools.cm_to_pt(8.5), JunTools.cm_to_pt(6.0))
actual_size = fig1.scene.viewport[].widths
println("   Default figure size: $(actual_size)")
println("   Expected size: $(expected_size)")
@assert abs(actual_size[1] - expected_size[1]) < 1 "Figure width incorrect"

# Test with custom size
fig2 = JunTools.publication_figure(size_cm = (17.8, 8.0))
expected_size2 = (JunTools.cm_to_pt(17.8), JunTools.cm_to_pt(8.0))
actual_size2 = fig2.scene.viewport[].widths
@assert abs(actual_size2[1] - expected_size2[1]) < 1 "Custom figure width incorrect"

# Test with different journal
fig3 = JunTools.publication_figure(journal = :nature)
nature_sizes = JunTools.journal_sizes(:nature)
expected_size3 = (JunTools.cm_to_pt(nature_sizes.single), JunTools.cm_to_pt(6.0))
actual_size3 = fig3.scene.viewport[].widths
@assert abs(actual_size3[1] - expected_size3[1]) < 1 "Nature figure width incorrect"

println("   ✓ Figure sizing working correctly")

## Test 3: Saving functionality - both patterns
println("\n3. Testing save_publication_figure...")

# Create a test figure
fig_test = JunTools.publication_figure()
ax_test = Makie.Axis(fig_test[1, 1], 
    xlabel = "Time (min)", 
    ylabel = "Signal (AU)",
    title = "Test Figure"
)
lines!(ax_test, x, sin.(x), linewidth = 2, color = :blue)

# Test Pattern 1: Full path (backward compatible)
full_path = joinpath(JunTools.get_plot_path(project_name), "test_full_path.pdf")
saved1 = JunTools.save_publication_figure(full_path, fig_test)
@assert isfile(saved1) "Pattern 1 save failed"
@assert saved1 == full_path "Pattern 1 path mismatch"
println("   ✓ Pattern 1 (full path): $(basename(saved1))")

# Test Pattern 2: Filename + directory (recommended)
plot_path = JunTools.get_plot_path(project_name)
saved2 = JunTools.save_publication_figure("test_filename_dir", fig_test, plot_path)
expected_path = joinpath(plot_path, "test_filename_dir.pdf")
@assert isfile(saved2) "Pattern 2 save failed"
@assert saved2 == expected_path "Pattern 2 path mismatch"
println("   ✓ Pattern 2 (filename + dir): $(basename(saved2))")

# Test different formats
saved_svg = JunTools.save_publication_figure("test_svg", fig_test, plot_path, format = "svg")
@assert isfile(saved_svg) "SVG save failed"
@assert endswith(saved_svg, ".svg") "SVG extension incorrect"
println("   ✓ SVG format: $(basename(saved_svg))")

## Test 4: Different journal formats
println("\n4. Testing journal-specific formatting...")

for journal in [:cell, :nature, :pnas]
    JunTools.set_publication_theme!(journal = journal, fontsize = 8)
    
    fig = JunTools.publication_figure(journal = journal)
    ax = Makie.Axis(fig[1, 1], 
        xlabel = "X axis", 
        ylabel = "Y axis",
        title = "$(uppercase(string(journal))) Format"
    )
    
    colors = Dict(:cell => :orange, :nature => :darkgreen, :pnas => :navy)
    lines!(ax, x, x.^2, color = colors[journal], linewidth = 2)
    
    # Test both save patterns for this journal
    filename = "test_$(journal)"
    saved = JunTools.save_publication_figure(filename, fig, plot_path)
    @assert isfile(saved) "$(journal) save failed"
    
    journal_size = JunTools.journal_sizes(journal)
    actual_width = fig.scene.viewport[].widths[1]
    expected_width = JunTools.cm_to_pt(journal_size.single)
    @assert abs(actual_width - expected_width) < 1 "$(journal) width incorrect"
    
    println("   ✓ $(journal): $(journal_size.single)cm → $(basename(saved))")
end

## Test 5: Font consistency
println("\n5. Testing font consistency...")

fig_fonts = JunTools.publication_figure()
ax_fonts = Makie.Axis(fig_fonts[1, 1],
    xlabel = "X Label (8pt)",
    ylabel = "Y Label (8pt)", 
    title = "Title (9pt)"
)

# Add various text elements to verify font sizes
text!(ax_fonts, 5, 0.5, text = "8pt text", fontsize = 8, color = :red)
text!(ax_fonts, 5, -0.5, text = "10pt comparison", fontsize = 10, color = :blue)
lines!(ax_fonts, x, sin.(x), linewidth = 2, color = :black)

saved_fonts = JunTools.save_publication_figure("test_fonts", fig_fonts, plot_path)
@assert isfile(saved_fonts) "Font test save failed"
println("   ✓ Font test: $(basename(saved_fonts))")

## Test 6: Error handling and edge cases
println("\n6. Testing edge cases...")

# Test automatic directory creation
temp_dir = joinpath(plot_path, "temp_subdir")
if isdir(temp_dir)
    rm(temp_dir, recursive=true)
end

saved_temp = JunTools.save_publication_figure("test_temp", fig_test, temp_dir)
@assert isdir(temp_dir) "Directory creation failed"
@assert isfile(saved_temp) "Save to new directory failed"
println("   ✓ Automatic directory creation")

# Test file extension detection
saved_png = JunTools.save_publication_figure(joinpath(plot_path, "test_ext.png"), fig_test)
@assert isfile(saved_png) "PNG extension test failed"
@assert endswith(saved_png, ".png") "PNG extension incorrect"
println("   ✓ File extension detection")

## Summary
println("\n" * "="^50)
println("✅ ALL TESTS PASSED!")
println("\n📏 Dimension Verification (check in Illustrator):")
println("   • Cell single: 8.5cm wide")
println("   • Nature single: 8.9cm wide") 
println("   • PNAS single: 8.7cm wide")
println("\n🔤 Font Verification:")
println("   • Axis labels: 8pt")
println("   • Titles: 9pt") 
println("   • Tick labels: 7pt")
println("\n📁 Test files saved to: $(plot_path)")
println("\n🚀 Ready for production use!")