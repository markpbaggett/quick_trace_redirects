import oaitools, parsecsv, strformat, times, xmltools

type
  TraceReport* = ref object
    ## Type to report successes and failures
    successes: seq[string]
    failures: seq[string]

proc get_new_records_from_digital_commons(oai_set: string): seq[string] =
  echo fmt"{'\n'}Getting records from {oai_set}. {'\n'}{'\n'}"
  var
    oai_connection = newOaiRequest("https://trace.tennessee.edu/do/oai/", oai_set)
    three_months_ago = (now() - 3.months)
    records = oai_connection.list_records(
      "qdc", from_date=three_months_ago.format("yyyy-MM-dd"))
  records

proc get_etd_titles(filename: string): seq[string] =
  var p: CsvParser
  p.open(filename, separator = '|')
  p.readHeaderRow()
  while p.readRow():
    result.add(p.rowEntry("title"))
  p.close

when isMainModule:
  echo get_etd_titles("/home/mark/Documents/spring_2019/theses.csv")
  let x = get_new_records_from_digital_commons("publication:utk_graddiss")
  echo x
  echo len(x)
  
