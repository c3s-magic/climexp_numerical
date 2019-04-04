# Python wrapper for climate explorer

## Prerequisites

* Climate explorer needs to be compiled.

## To create a new distribution:

```
python3 setup.py sdist
```

## To install:

```
pip install ./dist/climexp_numerical-1.0.tar.gz
```

## To test:

```
python test.py
```

## Docker:

```
docker build -f Dockerfile.conda -t climexp_numerical_conda .
docker build -f Dockerfile.python -t climexp_numerical_python .
docker run -ti -v `pwd`/data:/data -it climexp_numerical_python 
ncview ./data/out.nc
```
