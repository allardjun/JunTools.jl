using JunTools

@show JunTools.greet()

println()

@show JunTools.get_base_path("test_project")
@show JunTools.get_plot_path("test_project")
@show data_path = JunTools.get_data_path("test_project")

test_data = rand(10)

JunTools.save_plusplus(joinpath(data_path, "test_data"), test_data)
JunTools.save_plusplus(joinpath(data_path, "test_data"), test_data)

println("Files in data path:")
for file in readdir(data_path)
    println(file)
end