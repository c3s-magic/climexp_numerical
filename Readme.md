# KNMI Climate explorer

## Using climate explorer via Docker

### The docker image can be build with the following command:
```
docker build -t climexp_numerical .
```

### The docker container is now ready for use:

#### 1) First obtain data:
```
mkdir ./data/
wget "http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/nino3.nc" -O ./data/nino3.nc
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