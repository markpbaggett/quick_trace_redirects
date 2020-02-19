# Package

version       = "0.1.0"
author        = "Mark Baggett"
description   = "A binary to quickly create redirects from Trace objects in Islandora to objects in Digital Commons"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["quick_trace_redirects"]



# Dependencies

requires "nim >= 1.0.4"
requires "oaitools >= 0.2.3"
