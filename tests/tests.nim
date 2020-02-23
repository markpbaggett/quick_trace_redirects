import quick_trace_redirects, strformat, unittest

suite "Test Name Spacing":
  setup:
    let names = [("Mark", "Baggett", "", ""), ("Mark", "Baggett", "Patrick", ""), ("Mark", "Baggett", "Patrick", "Jr."), ("Mark", "Baggett", "", "Jr.")]

  test "Check name spacing works as expected":
    var check_position = 0
    for name in names:
      let 
        first = name[0]
        last = name[1]
        middle = get_spaced_name(name[2])
        suffix = get_spaced_name(name[3])
      if check_position == 0:
        check "Baggett, Mark" == fmt"{last}, {first}{middle}{suffix}"
      if check_position == 1:
        check "Baggett, Mark Patrick" == fmt"{last}, {first}{middle}{suffix}"
      if check_position == 2:
        check "Baggett, Mark Patrick Jr." == fmt"{last}, {first}{middle}{suffix}"
      if check_position == 3:
        check "Baggett, Mark Jr." == fmt"{last}, {first}{middle}{suffix}"
      check_position += 1

suite "Test Reading Digital Commons Data":
  setup:
    let
      xml_record = """
      <oai_dc:dc xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.bepress.com/OAI/2.0/qualified-dublin-core/ https://resources.bepress.com/assets/xsd/oai_qualified_dc.xsd">			
			<dc:title>My Sample ETD</dc:title>
			<dc:creator>Baggett, Mark Patrick</dc:creator>
			<dc:date.created>2018-12-01T08:00:00Z</dc:date.created>
			<dc:thesis.degree.level>Dissertation</dc:thesis.degree.level>
			<dc:thesis.degree.name>Doctor of Philosophy</dc:thesis.degree.name>
			<dc:thesis.degree.discipline>Physics</dc:thesis.degree.discipline>
			<dc:contributor>Robert Roberts</dc:contributor>
			<dc:contributor>Pig Champion, Jerry A., Kawakami Forever</dc:contributor>
			<dc:subject>beta decay</dc:subject>
			<dc:subject>neutron emission</dc:subject>
			<dc:subject>neutron spectroscopy</dc:subject>
			<dc:subject>beta-delayed neutron decay</dc:subject>
			<dc:subject>nuclear structure</dc:subject>
			<dc:subject>shell model</dc:subject>
			<dc:description.abstract>An abstract</dc:description.abstract>
			<dc:identifier>https://trace.tennessee.edu/utk_graddiss/99999999</dc:identifier>
      </oai_dc:dc>
      """
    var
      xml_records: seq[string]
    xml_records.add(xml_record)
    let
      digital_commons_data = get_all_digital_commons_authors_and_uris(xml_records)

  test "Make sure XML records are properly parsed":
    check "Baggett, Mark Patrick" == digital_commons_data[0][0]
    check "https://trace.tennessee.edu/utk_graddiss/99999999" == digital_commons_data[0][1]
  
  test "Make sure we can get all authors and uris from digital commons":
    check @[("Baggett, Mark Patrick", "https://trace.tennessee.edu/utk_graddiss/99999999")] == get_all_digital_commons_authors_and_uris(xml_records)
