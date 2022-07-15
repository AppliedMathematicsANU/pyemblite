#!/usr/bin/env python
import os
import glob
import numpy as np
from setuptools import setup, Extension, find_packages
from Cython.Build import cythonize
import Cython
from distutils.version import LooseVersion

if os.name.startswith('nt'):
    # windows does not have an easy way to find libraries/install them in a standard location?
    # to complicate things further, embree3 no longer comes with a windows installer, but the last
    # version to do so had "C:\Program Files\Intel\Embree3\" as the default installation location
    # so we'll use that.
    
    include_path = [np.get_include(), r'C:\Program Files\Intel\Embree3']
    libs = [r"C:\Program Files\Intel\Embree3\lib\embree3"]
else:
    include_path = [np.get_include(),]
    libs = ["embree3"]

define_macros = []
if LooseVersion(Cython.__version__) >= LooseVersion("3.0"):
    # Gets rid of compiler warning:
    #
    # warning: #warning "Using deprecated NumPy API, disable it with " "#define NPY_NO_DEPRECATED_API NPY_1_7_API_VERSION"
    #
    # But only for Cython version >= 3.0
    define_macros = [("NPY_NO_DEPRECATED_API", "NPY_1_7_API_VERSION")]

extensions = \
    list(
        [
            Extension(
                "pyemblite." + os.path.splitext(os.path.split(pyx_file)[1])[0],
                [pyx_file, ],
                include_dirs=include_path,
                libraries=libs,
                define_macros=define_macros,
            )
            for pyx_file in glob.glob(os.path.join("pyemblite", "*" + os.path.extsep + "pyx"))
        ]
    )
ext_modules = cythonize(extensions, include_path=include_path, language_level=3)

setup(
    name="pyemblite",
    version='0.0.2',
    ext_modules=ext_modules,
    zip_safe=False,
    packages=find_packages(),
    package_data={'pyemblite': ['*.pxd']},
    install_requires=[
        "numpy>=1.7",
    ],
    setup_requires=[
        "numpy>=1.7",
        "cython"
    ]
)
