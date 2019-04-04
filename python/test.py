#python3 setup.py sdist && pip install ./dist/climexp_numerical-1.0.tar.gz && python test.py 
#import logging
#logging.basicConfig(level=logging.DEBUG)
from climexp_numerical import climexp_numerical
import sys

def callback(message):
  sys.stdout.write('[test correlatefield]: ' + message)
  sys.stdout.flush()

climexp = climexp_numerical.ClimExp()
climexp.setClimExpHome("../build")
status = climexp.correlatefield(
                     observation="../data/cru_ts3.22.1901.2013.pre.dat.nc",
                     model="../data/nino3.nc",
                     frequency="mon",
                     timeselection="1:12",
                     averaging="ave",
                     lag=3,
                     out="/tmp/out.nc",
                     callback = callback
                     )

print("Status = %d" % status);