"""
Tate Mason & Craig A. Depken II - Housing Quality Variation by Race 
    UGA and UNC Charlotte
    08.26.2026
    
Code serves to format IPUMS data to be used in modeling and output files.
"""

#=== Environment Setup ===#

import os
import sys
from rich.traceback import install; install()
from rich.console import Console
console = Console()
# Data 
import pandas as pd # data handling and management
from ipumspy import IpumsApiClient, MicrodataExtract, readers # access IPUMS API
# Numerical and Statistical 
import numpy as np # numerical manipulation
import scipy as sp # statistical manipulation

# log creation
sys.stdout = open('data_format_output.txt', 'a')

# path
outPath = '../output/'

# switches
datCreate = 0 # call API and make dataset
prepPerc  = 1 # make percentiles for income, gross rent, home value, own%
prepDec   = 0 # same but deciles
prepDum   = 0 # make race dummies

#=== Data Call ===#


if datCreate:
    IPUMS_API_KEY = "59cba10d8a5da536fc06b59d023837cb08b94578b47c5eb8f7cf653b"
    client        = IpumsApiClient(IPUMS_API_KEY)
    extract       = MicrodataExtract(
    collection  = 'usa', # census
    description = 'housing_data', # name extract
    samples     = [
        'us1980a', 'us1980b', # 1980
        'us1990a', 'us1990b', # 1990
        'us2000a', 'us2000g', # 2000
        'us2010a',            # 2010
        'us2019a'             # 2019
    ], # samples needed
    variables   = [
        'YEAR',       # sample year
        'SAMPLE',     # sample id
        'SERIAL',     # household serial number
        'CBSERIAL',   # census serial number
        'HHWT',       # hh weight
        'CLUSTER',    # hh cluster (var est)
        'STRATA',     # hh strate (var est)
        'GQ',         # group quarters indicator
        'HHTYPE',     # household type
        'STATEFIP',   # state (fips code)
        'METRO',      # metro status (if applicable)
        'METAREA',    # metro area (pre-2013)
        'METAREAD',   # detailed metro area
        'MET2013',    # metro area (2013 delineations)
        'URBAN',      # urban indicator
        'FARM',       # farm status
        'OWNERSHP',  # ownership of dwelling
        'OWNERSHPD', # detailed ownership of dwelling
        'MORTOTAL',   # total monthly mortgage
        'RENT',       # monthly contract rent
        'RENTGRS',    # monthly gross rent
        'HHINCOME',   # total household income
        'VALUEH',     # house value
        'BUILTYR',    # age of structure
        'BUIlTYR2',   # age of structure, decades
        'BEDROOMS',   # n. bedrooms
        'NFAMS',      # n. families living in household
        'CBNSUBFAM',  # n. subfamilies living in household
        'PERNUM',     # person number in sample unit (1==head)
        'PERWT',      # person weight
        'SEX',        # sex
        'AGE',        # age
        'RACE',       # race
        'RACED',      # race (detailed codes)
        'EDUC',       # educational attainment
        'EDUCD',      # educational attainment (detailed)
        'OCC1990',    # occupation, 1990 basis
        'IND1990',    # industry, 1990 basis
        'INCTOT',     # total personal income
        'FTOTINC',    # total family income
        'INCWAGE',    # wage income
        'INCBUS',     # non-farm income
        'INCBUS00',   # business and farm income, 2000
        'INCFARM',    # income from farm
        'INCSS',      # social security income
        'INCWELFR',   # welfare income
        'INCINVST',   # interest, dividend, rental income
        'INCRETIR',   # retirement income
        'INCSUPP',    # supplemental security income
        'INCOTHER'    # other income
    ],
    )

#=== Submit and Download Extract ===#
    client.submit_extract(extract)
    console.print(f'Extract submitted! ID:{extract.extract_id}')

    client.wait_for_extract(extract)
    console.print('Extract is ready to download')

    client.download_extract(extract, download_dir='/Volumes/TDP/housing_data')

#=== Parse Extract ===#
ddi_file  = f'/Volumes/TDP/housing_data/{extract.collection}_{str(extract.extract_id).zfill(5)}.xml'
data_file = f'/Volumes/TDP/housing_data/{extract.collection}_{str(extract.extract_id).zfill(5)}.dat.gz'

ddi       = readers.read_ipums_ddi(ddi_file)
df        = readers.read_microdata(ddi, data_file)

console.print(df.head())

df.to_csv('/Volumes/TDP/housing_data/housing_sample.csv', index=False)

#=== Percentile Dummies ===#
if prepPerc:
    
