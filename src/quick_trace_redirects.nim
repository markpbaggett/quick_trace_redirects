import oaitools, parsecsv, strformat, times, xmltools, strutils, sequtils

type
  TraceReport* = ref object
    ## Type to report successes and failures
    successes: seq[string]
    failures: seq[string]

proc parse_data(response, element: string): seq[string] =
  let
    xml_response = Node.fromStringE(response)
    results = $(xml_response // element)
  for node in split(results, '<'):
    let value = node.replace("/", "").replace(fmt"{element}>", "")
    if len(value) > 0:
      result.add(value)

proc get_new_records_from_digital_commons(oai_set: string): seq[string] =
  echo fmt"{'\n'}Getting records from {oai_set}. {'\n'}{'\n'}"
  var
    oai_connection = newOaiRequest("https://trace.tennessee.edu/do/oai/", oai_set)
    three_months_ago = (now() - 3.months)
    records = oai_connection.list_records(
      "qdc", from_date=three_months_ago.format("yyyy-MM-dd"))
  records

proc get_digital_commons_title_and_uris(digital_commons_records: seq[string]): seq[(string, string)] =
  for record in digital_commons_records:
    let
      title = parse_data(record, "dc:title")[0]
      identifier = parse_data(record, "dc:identifier")[0]
    result.add((title, identifier))

proc get_islandora_etds(filename: string): seq[(string, string)] =
  var p: CsvParser
  p.open(filename, separator = '|')
  p.readHeaderRow()
  while p.readRow():
    result.add(
      (
        p.rowEntry("title"),
        p.rowEntry("DELETE_original_uri_from_utk").replace("EMBARGOED OR DELETED: ", "").replace("/datastream/PDF", "")
      )
      )
  p.close

proc compare_islandora_digital_commons_etds(islandora_etds, digital_commons_records: seq[(string, string)]): seq[int] =
  let
    islandora_titles = islandora_etds.mapIt(it[0])
    digital_commons_titles = digital_commons_records.mapIt(it[0])
  var
    islandora_position = 0
    digital_commons_position: int
  for title in islandora_titles:
    result.add(digital_commons_titles.find(title))
  # for islandora etd in islandora_etds.mapIt(it[0]):
  #   for digital_commons_etd in digital_commons_records:
  #     if islandora_etd == digital_commons_etd:
  #       if islandora_etd ==

  #   if etd[0] in digital_commons_records:
  #     result.successes.add(etd[0])
  #   else:
  #     result.failures.add(etd[0])


when isMainModule:
  let
    islandora_theses = get_islandora_etds("/home/mark/Documents/spring_2019/theses.csv")
    theses = get_digital_commons_title_and_uris(get_new_records_from_digital_commons("publication:utk_gradthes"))
    dissertations = get_digital_commons_title_and_uris(get_new_records_from_digital_commons("publication:utk_graddiss"))
  echo compare_islandora_digital_commons_etds(islandora_theses, theses)