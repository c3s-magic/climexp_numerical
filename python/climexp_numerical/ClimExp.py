import logging;
import sys
import os
from climexp_numerical import RunProcess

class ClimExp:
  def __init__(self):
    """Constructor for ClimExp"""
    self.climexpHome = "../build"

  def _callback(message):
    return
  
  def setClimExpHome(self, climexpHome):
    """Set the location where the climate explorer executables reside"""
    self.climexpHome = climexpHome
    
  def correlatefield(self,
                     observation="cru_ts3.22.1901.2013.pre.dat.nc",
                     model="nino3.nc",
                     frequency="mon",
                     timeselection="1:12",
                     averaging="ave",
                     lag=3,
                     out="out.nc",
                     callback = _callback):
    """Calls climate explorer's correlatefield, callback is called during execution"""
    correlateFieldExecutable = os.path.join(self.climexpHome, "correlatefield")
    args = [correlateFieldExecutable, observation, model, frequency, timeselection, averaging, str(lag), out]
    logging.debug("correlating " + str(args));
    status = RunProcess.RunProcess(args, callback, os.environ.copy(), 1)
    logging.debug("Return status = %d" % status)
    return status

