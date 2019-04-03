#!/usr/bin/env python

from distutils.core import setup

# Run python setup.py sdist


setup(name='climexp_numerical',
      version='1.0',
      description='Python interface to KNMI climate explorer',
      author='Geert Jan van Oldenborgh, Maarten Plieger',
      author_email='maarten.plieger@knmi.nl',
      packages=['climexp_numerical'],
      )
