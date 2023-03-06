#!/usr/bin/env python3
import xml.etree.ElementTree as ET


def truncate(l: list) -> list:
    if len(l) < 50:
        return l

    head = l[:15]
    msg = "\n\n--- 8< output was too long, middle lines are omitted >8 ---\n\n"
    tail = l[-15:]
    return [*head, msg, *tail]


def main():
    """
    Add content from <system-out> and <system-err> nodes to <failure> to make all
    unit test output visible in the Giltab web UI.

    If the ouptuts are longer than few dozens of lines, keep just start and end
    of the output
    """

    f: str = "report.xml"

    t = ET.parse(f)
    tcs = [
        tc
        for tc in t.findall("./testsuite/testcase")
        if [child for child in tc if child.tag == "failure"]
    ]

    tag_out, tag_err = "system-out", "system-err"
    h_log_old = "--------------------------------- Captured Log ---------------------------------"
    h_out_old = "--------------------------------- Captured Out ---------------------------------"
    h_log, h_out, h_err = "Captured Log:", "Captured Out:", "Captured Err:"

    for tc in tcs:
        outs = [el for el in tc if el.tag in [tag_out, tag_err]]
        system_out_orig = [i.text.splitlines() for i in outs if i.tag == tag_out]
        l = system_out_orig[0] if system_out_orig else []
        s_log = [h_log, *l[1 : l.index(h_out_old)]] if h_log_old in l else []
        s_log = truncate(s_log)
        s_out = [h_out, *l[l.index(h_out_old) + 1 :]] if h_log_old in l else []
        s_out = truncate(s_out)
        s_err = [i.text.splitlines()[1:] for i in outs if i.tag == tag_err]
        s_err = truncate([h_err, *s_err[0]] if s_err else [])
        msg = ["\n".join(i) for i in filter(None, [s_log, s_out, s_err])]

        tc.find("failure").text = "\n\n".join(msg)
        for el in outs:
            tc.remove(el)

    t.write(f)


if __name__ == "__main__":
    main()
