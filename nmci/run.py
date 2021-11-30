import subprocess


###############################################################################


def run(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
        encoding="utf-8", errors="ignore", check=True, *a, **kw):
    proc = subprocess.run(command, *a, shell=shell, stdout=stdout, stderr=stderr,
                          encoding=encoding, errors=errors, check=check, *kw)
    return (proc.stdout, proc.stderr, proc.returncode)


def command_output(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                   encoding="utf-8", errors="ignore", *a, **kw):
    output, err, code = run(command, *a, shell=shell, stdout=stdout, stderr=stderr,
                            encoding=encoding, errors=errors, *kw)
    assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
        % (command, code, output, err)
    return output


def command_output_err(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                       encoding="utf-8", errors="ignore", *a, **kw):
    output, err, code = run(command, *a, shell=shell, stdout=stdout, stderr=stderr,
                            encoding=encoding, errors=errors, *kw)
    assert code == 0, "command '%s' exited with code %d\noutput:\n%s\nstderr:\n%s" \
        % (command, code, output, err)
    return output, err


def command_code(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT,
                 encoding="utf-8", errors="ignore", check=False, *a, **kw):
    _, _, code = run(command, *a, shell=shell, stdout=stdout, stderr=stderr,
                     encoding=encoding, errors=errors, check=check, *kw)
    return code
