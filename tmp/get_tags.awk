BEGIN {ORS=" "}
/^\s*@/ { print $0 }
/^\s*Scenario/ { print "\n" }
