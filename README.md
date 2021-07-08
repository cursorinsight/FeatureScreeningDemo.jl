# FeatureScreeningDemo.jl
> Utility functions (e.g. plotting input data) and a complete example of running the Screener.

## Setup
Install Julia v >= 1.6.0.
Start Julia, and install the package:
```
$ julia
julia>     -- Press ]
(@v1.6) pkg> add FeatureScreeningDemo     -- TODO set correct path
(@v1.6) pkg>       -- Press Backspace
```
Don't exit, stay in Julia.

## Usage
Start Julia:
```
$ julia
```

Create a random feature dataset:
```
julia> using FeatureScreening

julia> feature_set = rand(FeatureSet, 25, 200; label_count = 5)
FeatureSet{Int64, Int64, Float64}<25 x 200>
```
### Plotting

```
julia> using PlotlyJS

julia> using FeatureScreeningDemo

julia> plot(feature_set)
```
![image](plot.jpg)

### Screening

Run a complete demo, that includes loading a HDF5 file, plotting it, and run the screener:
```
$ julia
julia> using FeatureScreeningDemo

julia> demo_screen(filename = "demo_blobs.hdf5")
[ Info: Loaded sample data from demo_blobs.hdf5
┌ Info: Sample data:
│   featureset =
│    FeatureScreening.Types.FeatureSet{String, Int64, Float64}<100 x 100>
│      + 5 labels
│      + 20 samples
│      + 100 features
└
[ Info: Saved plot to 20210623-203418/samples.html
[ Info: Now do the screening
size: 100
[ Info: Turn #1
[ Info: Turn #2
[ Info: Turn #3
[ Info: Turn #4
[ Info: Turn #5
[ Info: Turn #6
[ Info: Turn #7
[ Info: Turn #8
[ Info: Turn #9
[ Info: Turn #10
[ Info: Turn #11
[ Info: Turn #12
[ Info: Turn #13
[ Info: Turn #14
[ Info: Turn #15
[ Info: Turn #16
[ Info: Turn #17
[ Info: Turn #18
[ Info: Turn #19
[ Info: Turn #20
  2.780104 seconds (5.02 M allocations: 634.891 MiB, 3.12% gc time, 48.52% compilation time)
┌ Info: Screening result:
│   feature_names(selected) =
│    10-element Vector{Int64}:
│     30
│     27
│      9
│      6
│     95
│     92
│     67
│     71
│     21
└     75
```

If you don't give it a filename, it generates a demo feature space:
```
$ julia
julia> demo_screen()
[ Info: Loaded sample data from demo_blobs.hdf5
┌ Info: Sample data:
│   featureset =
│    FeatureScreening.Types.FeatureSet{String, Int64, Float64}<100 x 100>
│      + 5 labels
│      + 20 samples
│      + 100 features
└
[ Info: Saved plot to 20210623-203418/samples.html
[ Info: Now do the screening
size: 100
[ Info: Turn #1
[ Info: Turn #2
[ Info: Turn #3
[ Info: Turn #4
[ Info: Turn #5
[ Info: Turn #6
[ Info: Turn #7
[ Info: Turn #8
[ Info: Turn #9
[ Info: Turn #10
[ Info: Turn #11
[ Info: Turn #12
[ Info: Turn #13
[ Info: Turn #14
[ Info: Turn #15
[ Info: Turn #16
[ Info: Turn #17
[ Info: Turn #18
[ Info: Turn #19
[ Info: Turn #20
  2.780104 seconds (5.02 M allocations: 634.891 MiB, 3.12% gc time, 48.52% compilation time)
┌ Info: Screening result:
│   feature_names(selected) =
│    10-element Vector{Int64}:
│     30
│     27
│      9
│      6
│     95
│     92
│     67
│     71
│     21
└     75
```

You can now check out directory 20210623-203418 and open the plot "sample.html" from your browser.
