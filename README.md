# FeatureScreeningDemo.jl

## Installation
You need Julia >= v1.6.0.

```julia
add "ssh://git@github.com/cursorinsight/FeatureScreeningDemo.jl"#master
```

### Set up for non-julia users
Install Julia >= v1.6.0. You can install it with [asdf](https://asdf-vm.com/).

Clone the project
```bash
$ git clone git@github.com:cursorinsight/FeatureScreeningDemo.jl.git
$ cd FeatureScreeningDemo.jl/
$ julia --project
```
```julia
julia>                                   -- Press ']'
(FeatureScreeningDemo) pkg> instantiate
(FeatureScreeningDemo) pkg> build
(FeatureScreeningDemo) pkg>              -- Press Backspace
```

### Good to have
Install hdf5-tools to get a lot different tools for HDF5 files. For example:
- `h5dump`: enables the user to examine the contents of an HDF5 file and dump
those contents in human readable form

```bash
$ sudo apt install hdf5-tools
```

## Usage
This application demonstrates the usage and usefulness of our random-forest
based feature screening method. You can run a complete `demo` to test all
functionality with random feature sets, run `benchmark` to measure your data set
accuracy or `screen` you feature set to get a reduced one.

### Generate synthetic data
You can use our
[BiometricBlender](https://github.com/cursorinsight/biometricblender) to
generate synthetic data. You can find more information its project `README.md`.
To test the funcionallity you can generate a data set with the following
parameters:

```bash
python -m biometric_blender \
    --n-labels 100 \
    --n-samples-per-label 64 \
    --n-true-features 100 \
    --n-fake-features 300 \
    --min-usefulness 0.5 \
    --max-usefulness 1 \
    --location-sharing-extent 100 \
    --location-ordering-extent 50 \
    --n-features-out 10000 \
    --blending-mode logarithmic \
    --min-count 4 \
    --max-count 8
```

### Create a random feature dataset
If you don't have a valid dataset to test the features, you can generate random
training feature set.

```julia
using FeatureScreening.Types: FeatureSet, save
feature_set = rand(FeatureSet, 25, 200; label_count = 5)
save(feature_set)
```

## CLI usage
You can use our implementation from command line too. To get the proper usage of
the commands, see the next section about the `--help` option.

### `-h|--help` option
You can run `julia --project src/main.js` command with `-h|--help` option to get
a short description about the application and the proper usage.

### `demo` command
This command demonstrates most of the features of this demo application.
1. Generate random train feature set
2. Screen the train data set
3. Run benchmarks on
    - the original train feature set,
    - the hypothetical best subset of the original feature set and
    - the screened subset.

Usage:
```bash
$ julia --project src/main.jl demo
```

### `benchmark` command
This command benchmarks the given training feature set.

Usage:
```bash
$ julia --project src/main.jl \
    benchmark \
    [--config <config>] \
    [--output <result_dictionary>] \
    <training-data-hdf5> \
    [<test-data-hdf5>]
```

If you don't have valid dataset, you can generate random training feature set.
You can find the steps for that under `Create random feature dataset` heading.

### `screen` command
This command screens the given feature set and splits that into a train and a
test data.

Usage:
```bash
$ julia --project src/main.js \
    screen \
    [--config <config>] \
    [--output <result_dictionary>] \
    <training-data-hdf5>
```

If you don't have valid dataset, you can generate random training feature set.
You can find the steps for that under `Create random feature dataset` heading.
