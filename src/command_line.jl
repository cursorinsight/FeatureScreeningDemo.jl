###-----------------------------------------------------------------------------
### Copyright (C) 2021- Cursor Insight
###
### All rights reserved.
###-----------------------------------------------------------------------------
# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/14

###=============================================================================
### __main__
###=============================================================================

module __CommandLine__main__

import FeatureScreeningDemo.Utilities.CommandLine: description
using FeatureScreeningDemo.Utilities.CommandLine: @Cmd_str

# TODO https://github.com/cursorinsight/FeatureScreeningDemo.jl/issues/11
function description(::Cmd"__main__")::String
    return """
    This application demonstrates the usage and usefullness of our feature
    screening method. You can run a completed "demo", run some "benchmark"
    to measure your feature set or "screen" that.
    """
end

end # module

###=============================================================================
### Commands
###=============================================================================

include("commands/demo.jl")
include("commands/benchmark.jl")
include("commands/screen.jl")
