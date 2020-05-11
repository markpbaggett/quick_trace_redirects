# Package

version       = "0.2.0"
author        = "Mark Baggett"
description   = "A binary to quickly create redirects from Trace objects in Islandora to objects in Digital Commons"
license       = "GPL-3.0"
srcDir        = "src"
bin           = @["quick_trace_redirects"]


# Dependencies

requires "nim >= 1.0.2"
requires "oaitools >= 0.2.5"
requires "csvtools >= 0.2.0"
requires "uuids >= 0.1.10"
requires "argparse >= 0.10.0"

# Tests

task test, "Test":
  exec "nim c -r tests/tests.nim"
