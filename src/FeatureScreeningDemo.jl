###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------

module FeatureScreeningDemo

###=============================================================================
### Exports
###=============================================================================

export demo_screen

###=============================================================================
### Imports
###=============================================================================

include("CommandLine.jl")
include("commands.jl")

include("Visualization.jl")

using FeatureScreening: FeatureSet, load, names, screen
using FeatureScreening.Types: features

using Dates: format, now
using PlotlyJS: plot, scatter, savefig
using Base: @elapsed

###=============================================================================
### Main
###=============================================================================

function demo_screen(; filename::String = "", kwargs...)
    out_dir = format(now(), "yyyymmdd-HHMMSS")
    mkdir(out_dir)
    report_file = open(out_dir * "/screening_report.txt", "w+")

    if filename != ""
        feature_set = load(filename)
        @info "Loaded sample data from $(filename)"
    else
        feature_set = rand(FeatureSet, 25, 200; label_count = 5)
        @info "Generated test sample data"
    end

    println(report_file, "Sample data:")
    show(report_file, feature_set)
    show(
        IOContext(report_file, :limit => true),
        "text/plain",
        features(feature_set),
    )
    println(report_file)

    plot_file = out_dir * "/samples.html"
    savefig(plot(feature_set), plot_file)
    @info "Saved samples plot to $(plot_file)"

    @info "Now do the screening"
    runtime = @elapsed selected = screen(feature_set; kwargs...)
    println(
        report_file,
        "Screening done: $(runtime) seconds, result:\n",
        names(selected),
    )
    @info "Screening done"

    selected_idxs = [feature_set.name_idxs[name] for name in names(selected)]
    plot_file = out_dir * "/selected.html"
    savefig(
        plot(
            scatter(;
                y = selected_idxs,
                text = names(selected),
                mode = "markers",
                marker_size = 10,
            ),
        ),
        plot_file,
    )
    @info "Saved selected plot to $(plot_file)"

    close(report_file)
end

end # module
