# KNMI Climate explorer

The KNMI climate explorer software can be used to do climate data analysis via a set of predefined climate data analysis functions.

Available functions:
1) Correlate field: Correlate field is a tool to correlate a field series to a point series to give fields of correlation coefficients, probabilities that these are significant, and the fit coefficients a, b and their errors.
   
   Settings (see Python example below):
   1) observation: Gridded observation dataset, like cru, example data is available [here](http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/cru_ts3.22.1901.2013.pre.dat.nc).
   2) model: Timeseries of modeldata, like El Nino. Example data is available [here](http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/nino3.nc)
   3) frequency: The time frequency, allowed value is at the moment "mon",
   4) timeselection: Select which months you want to use, e.g "1:12" means January till December
   5) averaging: The averaging method, currently "ave" is supported
   6) lag: The time lag in the selected frequency, a lag of 3 means that the correlation of the two variables will be shifted with three months.
   7) out="correlationresult.nc": The output filelocation and name
   8) callback=callback: This is an optional callback function which can be used to print the progress and status of ongoing calculations. It is used to provide status to PyWPS.

## Using the climate explorer via Docker

Since the climate explorer code is written in Fortran, and has many dependencies, it can be difficult to compile and run the climate explorer on your workstation. To overcome this problem A docker image can be build containing the climate explorer tooling. The docker image allows you to build an isolated version and use the climate explorer on different environments. 

### The docker image can be build with the following command:
```
docker build -t climexp_numerical .
```

### The docker container is now ready for use:

#### 1) First obtain data:
```
mkdir ./data/
# Retrieve model data:
wget "http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/nino3.nc" -O ./data/nino3.nc
# Retrieve observation data:
wget "http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/cru_ts3.22.1901.2013.pre.dat.nc" -O ./data/cru_ts3.22.1901.2013.pre.dat.nc
```
#### 2) Second run correlate field using the docker:

Correlate field is a tool to correlate a field series to a point series  to give fields of correlation coefficients, probabilities that these are significant, and the fit coefficients a, b and their errors.

The data folder is mounted into the docker container at the /data/ folder. Output is written to /data/out.nc. The output is a NetCDF file which you can inspect with ncdump or ncview. The output data can also be used with adaguc-server.
```
docker run --ulimit stack=827771699:827771699 -ti -v `pwd`/data:/data -it climexp_numerical bash -c "/src/climexp/build/correlatefield /data/cru_ts3.22.1901.2013.pre.dat.nc /data/nino3.nc mon 1:12 ave 3 /data/out.nc"
ncview ./data/out.nc 

```

## Python wrapper for climate explorer:

A python wrapper for the climate explorer is available in the python folder. It can be used to controll the climate explorer from python, which is usefull to wrap this code for example in PyWPS. This is done in https://github.com/c3s-magic/climexp_numerical_wps. 

### Which functions from climate explorer are already available via the WPS?
1) Correlatefield: This is a tool to correlate a field series to a point series to give fields of correlation coefficients, probabilities that these are significant, and the fit coefficients a, b and their errors.

The python wrapper for climate explorer can be used in the following way:

```
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
```

There is also a Docker container available for the python wrapper. To build and run it using Docker, do:

```
docker build -f Dockerfile.conda -t climexp_numerical_conda .
docker build -f Dockerfile.python -t climexp_numerical_python .
docker run -ti -v `pwd`/data:/data -it climexp_numerical_python 
ncview ./data/out.nc
```

# Contributors

© Copyright 2019: Geert Jan van Oldenborgh, Maarten Plieger