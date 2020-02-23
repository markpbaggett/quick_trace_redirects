import oaitools, parsecsv, strformat, times, xmltools, strutils, sequtils, csvtools, uuids, argparse


type Redirect = object
  ## This type captures all metadata for what we consider a redirect.  This is designed to work seamlessly with csvtools.
  a_type: string
  hash: string
  source: string
  source_options: string
  redirect: string
  redirect_options: string
  status: int


proc newRedirect(source, destination: string): Redirect = 
  ## Constructs a redirect.
  ##
  ## Args:
  ##
  ##   `source`: A URI to the object in Islandora.
  ##   `destination`: A URI to the object in Digital Commons.
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
  ##
  ##    let my_redirect = newRedirect(source="/islandora/object/utk.ir.td:12280", destination="https://trace.tennessee.edu/utk_gradthes/5482")
  ##    doAssert typeof(my_redirect) is Redirect
  ##
  return Redirect(a_type: "redirect", hash: $(genUUID()), source: source, source_options: "a:0:{}", redirect: destination, redirect_options: "a:1:{s:5:\"https\";b:1;}", status: 1)

proc get_spaced_name*(name: string): string =
  ## Takes a name part as a string and returns a space then the name part if the string is not empty.
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
  ##
  ##    doAssert " Patrick" == get_spaced_name("Patrick")
  ##    doAssert "" == get_spaced_name("")
  ##
  if name != "":
    return fmt" {name}"
  else:
    return name

proc parse_data(response, element: string): seq[string] =
  ## Takes an XML doc as a string and an element name and returns the text values of the element name as a sequence of strings.
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
  ##
  ##    let xml_record = """
  ##      <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.bepress.com/OAI/2.0/qualified-dublin-core/ https://resources.bepress.com/assets/xsd/oai_qualified_dc.xsd">
  ##      <dc:title>My Sample ETD</dc:title>
  ##      <dc:creator>Baggett, Mark Patrick</dc:creator>
  ##      <dc:identifier>https://trace.tennessee.edu/utk_graddiss/99999999</dc:identifier>
  ##      </oai_dc:dc>
  ##      """
  ##    doAssert @["https://trace.tennessee.edu/utk_graddiss/99999999"] == parse_data(xml_record, "dc:identifier")
  ##
  let
    xml_response = Node.fromStringE(response)
    results = $(xml_response // element)
  for node in split(results, '<'):
    let value = node.replace(fmt"/{element}>", "").replace(fmt"{element}>", "")
    if len(value) > 0:
      result.add(value)

proc get_new_records_from_digital_commons(oai_set: string): seq[string] =
  ## Gets all records published in the past 3 months from a set in the UTK instance of Digital Commons as a sequence of strings.
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
  ##
  ##    let recent_dissertations = get_new_records_from_digital_commons("publication:utk_graddis")
  ##    echo recent_dissertations
  ##
  echo fmt"{'\n'}Getting records from {oai_set}. {'\n'}{'\n'}"
  var
    oai_connection = newOaiRequest("https://trace.tennessee.edu/do/oai/", oai_set)
    three_months_ago = (now() - 3.months)
    records = oai_connection.list_records(
      "qdc", from_date=three_months_ago.format("yyyy-MM-dd"))
  records

proc get_all_digital_commons_authors_and_uris*(digital_commons_records: seq[string]): seq[(string, string)] =
  ## Takes a sequence of digital commons records and returns just the creator and identifier for each as a sequence of tuples with two string values.
  ##
  ## Examples:
  ##
  ## .. code-block:: nim
  ##
  ##    let xml_record = """
  ##      <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.bepress.com/OAI/2.0/qualified-dublin-core/ https://resources.bepress.com/assets/xsd/oai_qualified_dc.xsd">			
  ##      <dc:title>My Sample ETD</dc:title>
  ##      <dc:creator>Baggett, Mark Patrick</dc:creator>
  ##      <dc:identifier>https://trace.tennessee.edu/utk_graddiss/99999999</dc:identifier>
  ##      </oai_dc:dc>
  ##      """
  ##    var dc_records = @[xml_record]
  ##    doAssert @[("Baggett, Mark Patrick", "https://trace.tennessee.edu/utk_graddiss/99999999")] == get_all_digital_commons_authors_and_uris(dc_records)
  ##
  for record in digital_commons_records:
    let
      creator = parse_data(record, "dc:creator")[0]
      identifier = parse_data(record, "dc:identifier")[0]
    result.add((creator, identifier))

proc get_islandora_etds(filename: string): seq[(string, string)] =
  ## Reads a CSV and returns a sequence of tuples with the author name and link to the object in Islandora.
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
  ## Compares a sequence of objects in Islandora to objects in Digital Commons and returns a sequence of Redirects.
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

proc compare_and_write_redirects(oai_set: string, output_path:string, theses: seq[(string, string)]): int =
  ## Main procedure used to compare uris and write our csv.
  let
    etds_redirects = compare_islandora_digital_commons_etds(
      theses,
      get_all_digital_commons_authors_and_uris(get_new_records_from_digital_commons(oai_set))
      )
  etds_redirects.writeToCsv(output_path, separator='|', quote='\'')
  len(etds_redirects)

when isMainModule:
  var
    p = newParser("Quick Trace Redirects"):
      option("-e", "--etd_type", help="Specify thesis or dissertation check. Defaults to thesis.", default="thesis", choices = @["thesis", "dissertation"])
      option("-d", "--digital_commons_csv", help="The full path to your csv that was imported into Digital Commons.")
      option("-o", "--output_path", help="Path to where you want to write your output.", default="migrated_etds_append.csv")
    argv = commandLineParams()
    opts = p.parse(argv)
    total_redirects: int
  if opts.digital_commons_csv != "":
    let
      islandora_theses = get_islandora_etds(opts.digital_commons_csv)
    case opts.etd_type
    of "thesis":
      total_redirects = compare_and_write_redirects("publication:utk_gradthes", opts.output_path, islandora_theses)
      echo fmt"{'\n'}Wrote {total_redirects} to {opts.output_path}.{'\n'}"
    of "dissertation":
      total_redirects = compare_and_write_redirects("publication:utk_graddis", opts.output_path, islandora_theses)
      echo fmt"{'\n'}Wrote {total_redirects} to {opts.output_path}.{'\n'}"
