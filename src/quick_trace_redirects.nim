import oaitools, parsecsv, strformat, times, xmltools, strutils, sequtils, csvtools, uuids


type Redirect = object
  a_type: string
  hash: string
  source: string
  source_options: string
  redirect: string
  redirect_options: string
  status: int


proc newRedirect(source, destination: string): Redirect = 
  return Redirect(a_type: "redirect", hash: $(genUUID()), source: source, source_options: "a:0:{}", redirect: destination, redirect_options: "a:1:{s:5:\"https\";b:1;}", status: 1)

proc get_spaced_name(name: string): string =
  if name != "":
    return fmt" {name}"
  else:
    return name

proc parse_data(response, element: string): seq[string] =
  let
    xml_response = Node.fromStringE(response)
    results = $(xml_response // element)
  for node in split(results, '<'):
    let value = node.replace(fmt"/{element}", "").replace(fmt"{element}>", "")
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
      title = parse_data(record, "dc:creator")[0]
      identifier = parse_data(record, "dc:identifier")[0]
    result.add((title, identifier))

proc get_islandora_etds(filename: string): seq[(string, string)] =
  var p: CsvParser
  p.open(filename, separator = '|')
  p.readHeaderRow()
  while p.readRow():
    let
      last_name = p.rowEntry("author1_lname")
      first_name = p.rowEntry("author1_fname")
      middle_name = p.rowEntry("author1_mname")
      suffix = p.rowEntry("author1_suffix")
    result.add(
      (
        fmt"{last_name}, {first_name}{get_spaced_name(middle_name)}{get_spaced_name(suffix)}",
        p.rowEntry("DELETE_original_uri_from_utk").replace("EMBARGOED OR DELETED: ", "").replace("/datastream/PDF", "")
      )
      )
  p.close

proc compare_islandora_digital_commons_etds(islandora_etds, digital_commons_records: seq[(string, string)]): seq[Redirect] =
  let
    islandora_titles = islandora_etds.mapIt(it[0])
    digital_commons_titles = digital_commons_records.mapIt(it[0])
  for title in islandora_titles:
    let 
      dc_location = digital_commons_titles.find(title)
    if dc_location != -1:
      result.add(
        newRedirect(
          islandora_etds[islandora_titles.find(title)][1].replace("https://trace.utk.edu", ""),
          digital_commons_records[dc_location][1]
          )
        )
    else:
      result.add(
        newRedirect(
          islandora_etds[islandora_titles.find(title)][1].replace("https://trace.utk.edu", ""),
           "Missing"
          )
        )

when isMainModule:
  let
    islandora_theses = get_islandora_etds("/home/mark/Documents/spring_2019/theses.csv")
    theses = get_digital_commons_title_and_uris(get_new_records_from_digital_commons("publication:utk_gradthes"))
    dissertations = get_digital_commons_title_and_uris(get_new_records_from_digital_commons("publication:utk_graddiss"))
    theses_redirects = compare_islandora_digital_commons_etds(islandora_theses, theses)
  theses_redirects.writeToCsv("test.csv", separator='|', quote='\'')
