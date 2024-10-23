using JunTools

@show JunTools.greet()

println()

@show JunTools.get_base_path("test_project")
@show JunTools.get_plot_path("test_project")
@show JunTools.get_data_path("test_project")