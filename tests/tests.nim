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
    