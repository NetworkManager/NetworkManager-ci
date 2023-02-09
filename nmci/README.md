# NMCI - NetworkManager-ci Library

## Adding standard python module (e.g. `nmci.prepare`)

When created, do not forget to import it at the end of `__init__.py`, otherwise it will not be imported with `import nmci`.

## Adding new module as class (e.g. `nmci.process`)

If module is written as python class `_ClassMod` in `classmod.py`, do not forget to

1. Define `_module = _ClassMod()` at the end of file
2. Define `__getattr__()` to support avoid not fully loaded modules within nmci

```python
def __getattr__(attr):
    return getattr(_module, attr)
```

3. Add module to `__init__.py`

```python
import nmci.classmod
# this line is important for autocomplete to work correctly
classmod = nmci.classmod._module
sys.modules["nmci.classmod"] = classmod
```

Remember, if you define another classes in `classmod.py`, they will not be accessible,
unless you set them as attributes of `_ClassMod`.