# python3 setup.py sdist
# pip install ./dist/climexp_numerical-1.0.tar.gz && python test.py
# import logging
# logging.basicConfig(level=logging.DEBUG)

from climexp_numerical import climexp_numerical
import sys
import os


def callback(message):
    sys.stdout.write('[test correlatefield]: ' + message)
    sys.stdout.flush()


climexp = climexp_numerical.ClimExp()
climexpBuild = os.getenv("CLIMATE_EXPLORER_BUILD", "../build")
climexpData = os.getenv("CLIMATE_EXPLORER_DATA", "../data")
climexp.setClimExpHome(climexpBuild)
observationData = os.path.join(climexpData, "cru_ts3.22.1901.2013.pre.dat.nc")
modelData = os.path.join(climexpData, "nino3.nc")
status = climexp.correlatefield(observation=observationData,
                                model=modelData,
                                frequency="mon",
                                timeselection="1:12",
                                averaging="ave",
                                lag=3,
                                out="/tmp/out.nc",
                                callback=callback
                                )

print("Status = %d" % status)
