import sys
import xml.etree.ElementTree as ET

test_count = 0
testsuite = ET.Element('testsuite')
for file_name in sys.argv[1:]:
    try:
        with open(file_name) as f:
            junit = ET.fromstring(f.read())
            test_count += int(junit.attrib["tests"])
            testsuite.extend(junit.getchildren())
    except Exception as e:
        sys.stderr.write("error while file: " + file_name + "\n" + str(e))

testsuite.attrib["tests"] = str(test_count)
print(ET.tostring(testsuite, "utf-8").decode("utf-8"))
