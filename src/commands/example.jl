###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

###=============================================================================
### Imports
###=============================================================================

# Command API
import .CommandLine: compile, execute
using .CommandLine: Settings, @cmd_str, @add_arg_table!

using FeatureScreening.Types: load, FeatureSet
using FeatureScreening: screen, accuracies
using FeatureScreening.Utilities: ExpStep

###=============================================================================
### Command API
###=============================================================================

function compile(::Type{Settings}, ::cmd"example")::Settings
    return @add_arg_table! Settings(prog = "example") begin
    end
end

function execute(::cmd"example")::Integer
    return main()
end

###=============================================================================
### API
###=============================================================================

function main(#path::AbstractString
              ;
              no_selected = 100,
              reduced_size::Integer = 32,
              screen_config = (;),
              test_config = (;),

              # TODO remove, this is temporary
              no_features::Integer = 256,
              no_samples::Integer = 300,
              label_count::Integer = 10
             )::Integer

    feature_set::FeatureSet =
        rand(FeatureSet,
             no_samples,
             no_features;
             label_count = label_count
            )[:, no_features:-1:1]

    top::FeatureSet =
        feature_set[:, no_features:-1:(no_features-no_selected+1)]

    selected::FeatureSet =
        screen(feature_set;
               reduced_size = no_selected,
               step_size = 2 * no_selected,
               config = screen_config)

    config = test_config
    all_acc         = accuracies(feature_set; config) # |> Dict # TODO more idxs
    top_acc         = accuracies(top; config)         # |> Dict
    selected_acc    = accuracies(selected; config)    # |> Dict

    @info "Waving" all_acc top_acc selected_acc
    return 0
end
