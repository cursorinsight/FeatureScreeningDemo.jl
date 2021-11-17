# FeatureScreeningDemo.jl

## Setup
Install Julia v >= 1.6.0. You can install it with [asdf](https://asdf-vm.com/).

```
$ asdf plugin-add julia
$ asdf install julia 1.6.3 && asdf global julia 1.6.3
```
Install `unzip`
```
$ sudo apt install unzip
```

Clone the project
```
$ git clone git@github.com:cursorinsight/FeatureScreeningDemo.jl.git
$ cd FeatureScreeningDemo.jl/
$ julia --project

julia>                                   -- Press ']'
(FeatureScreeningDemo) pkg> instantiate
(FeatureScreeningDemo) pkg> build        -- Press Backspace
```

### Good to have
Install hdf5-tools to get a lot different tools for HDF5 files. For example:
- h5dump: enables the user to examine the contents of an HDF5 file and dump
those contents in human readable form

```
sudo apt install hdf5-tools
```

## Commands

### demo
This command demonstrates most of the features of this demo application.
1. Generate random train feature set
2. Screen the train data set
3. Run benchmarks on
    - the original train feature set,
    - the hypothetical best subset of the original feature set and
    - the screened subset.

```
$ julia --project src/main.jl demo
```

### benchmark
This command benchmarks a feature set. For using the `benchmark` command you
have to provide the train data. 

If you don't have valid dataset, you can generate random training feature set.
You can find the steps for that under `Create random feature dataset` heading.

Syntax: `benchmark [--config CONFIG] [--output OUTPUT] train [test]`. The
`--config`, `--output` and `test` parameters are optionals.

```
$ julia --project src/main.jl benchmark \
    --config config.json \
    --output RESULT_DICT/ \
    <training-data-hdf5> \
    <test-data-hdf5>
```

### screen
This command screens a feature set. For using the `screen` command you have to
provide the train data. 

If you don't have valid dataset, you can generate random training feature set.
You can find the steps for that under `Create random feature dataset` heading.

Syntax: `screen [--config CONFIG] [--output OUTPUT] path`. The `--config`
and `--output` parameters are optionals. `path` parameter is the path of the
feature set.

```
$ julia --project src/main.js screen \
    --config config.json \
    --output RESULT_DICT/
    <training-data-hdf5>
```

### Create a random feature dataset
```
$ julia --project
julia> using FeatureScreening.Types: FeatureSet, save
julia> feature_set = rand(FeatureSet, 25, 200; label_count = 5)
FeatureSet{Int64, Int64, Float64}<25 x 200>
julia> save(feature_set)
```
