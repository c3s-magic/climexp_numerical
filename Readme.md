# Climate explorer

# Docker

## The docker can be build with the following command
```
docker build -t climexp_numerical .
```

## Run correlatefield with the climate explorer docker

### First obtain data:
```
mkdir ./data/
wget "http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/nino3.nc" -O ./data/nino3.nc
wget "http://opendap.knmi.nl/knmi/thredds/fileServer/climate_explorer/cru_ts3.22.1901.2013.pre.dat.nc" -O ./data/cru_ts3.22.1901.2013.pre.dat.nc
```
### Second run correlate field using the docker:

The data folder is mounted into the docker at /data/. Output is written to /data/out.nc
```
docker run --ulimit stack=827771699:827771699 -ti -v `pwd`/data:/data -it climexp_numerical bash -c "/src/climexp/build/correlatefield /data/cru_ts3.22.1901.2013.pre.dat.nc /data/nino3.nc mon 1:12 ave 3 /data/out.nc"
ncview ./data/out.nc 

```

# Python wrapper Docker:

A python wrapper for the correlatefield is available in the python folder.

To build and run it using Docker, do:

```
docker build -f Dockerfile.conda -t climexp_numerical_conda .
docker build -f Dockerfile.python -t climexp_numerical_python .
docker run -ti -v `pwd`/data:/data -it climexp_numerical_python 
ncview ./data/out.nc
```