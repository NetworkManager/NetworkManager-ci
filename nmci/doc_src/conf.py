import sys
import os


sys.path.extend([os.path.abspath(".."), os.path.abspath("../..")])

extensions = [
    "sphinx_markdown_builder",
    "sphinx.ext.autodoc",
]

exclude_patterns = ["*.md"]


autoclass_content = "init"

autodoc_default_options = {
    "member-order": "bysource",
    "undoc-members": False,
    "exclude-members": "also_needs, do_cleanup",
}
