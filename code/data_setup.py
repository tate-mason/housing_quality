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
#sys.stdout = open('data_format_output.txt', 'a')

# path
outPath = '../output/'

# switches
datCreate = 0 # call API and make dataset
prepPerc  = 0 # make percentiles for income, gross rent, home value, own%
prepDec   = 0 # same but deciles
prepDum   = 1 # make race dummies

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
        'OWNERSHP',   # ownership of dwelling
        'OWNERSHPD',  # detailed ownership of dwelling
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

# function to calculate percentile/decile
def weighted_quant_series(group, val_col, weight_col, q=100):
    valid_mask = group[val_col].notna() & group[weight_col].notna()
    if not valid_mask.any():
        return pd.Series(np.nan, index=group.index)

    sub = group[valid_mask].sort_values(val_col)

# midpoint weight proportion
    cum_weights  = sub[weight_col].cumsum()
    norm_weights = (cum_weights - 0.5*sub[weight_col]) / sub[weight_col].sum()

    bins = pd.cut(
        norm_weights,
        bins           = np.linspace(0, 1, q+1),
        labels         = range(1, q+1),
        include_lowest = True
    ).astype(float)

    return bins.reindex(group.index)

#=== Percentile Dummies ===#

if prepPerc:
    raw_ipums_sample              = pd.read_csv('/Volumes/TDP/housing_data/housing_sample.csv')
    raw_ipums_sample.columns      = raw_ipums_sample.columns.str.lower()

    raw_ipums_sample['inc_month'] = raw_ipums_sample['inctot']/12
    raw_ipums_sample['renter']    = ((raw_ipums_sample['ownershp']>0) & (raw_ipums_sample['ownershp']==2)).astype(int) # dummy for if renter neglecting NA
    raw_ipums_sample['own100']    = 100*(1-raw_ipums_sample['renter'])

    raw_ipums_sample['rent_inc']  = np.where(
            raw_ipums_sample['inctot'] > 0, # has income
            100*raw_ipums_sample['rentgrs'] / (raw_ipums_sample['inctot']/12), # rent as percent of monthly income
            np.nan
    )

    raw_ipums_sample['hval_inc']  = np.where(
            raw_ipums_sample['inctot'] > 0, # has income
            raw_ipums_sample['valueh']/(raw_ipums_sample['inctot']/12), # home value as percent of monthly income
            np.nan
    )

    gap_vars = ['rentgrs', 'valueh', 'own100', 'inc_month'] # defining the variables for gap regressions
    years    = raw_ipums_sample['year'].unique()


    for v in gap_vars:
        console.print(f'Computing {v} percentiles...')
        raw_ipums_sample[f'pctr_{v}'] = raw_ipums_sample.groupby('year', group_keys=False).apply(
            weighted_quant_series,
            val_col     = v,
            weight_col  = 'hhwt',
            q           = 100
        )

    raw_ipums_sample.to_parquet('/Volumes/TDP/housing_data/fig2_data.parquet')

if prepDec:

    raw_ipums_sample              = pd.read_csv('/Volumes/TDP/housing_data/housing_sample.csv')
    raw_ipums_sample.columns      = raw_ipums_sample.columns.str.lower()

    raw_ipums_sample['inc_month'] = raw_ipums_sample['inctot']/12
    raw_ipums_sample['renter']    = ((raw_ipums_sample['ownershp']>0) & (raw_ipums_sample['ownershp']==2)).astype(int) # dummy for if renter neglecting NA
    raw_ipums_sample['own100']    = 100*(1-raw_ipums_sample['renter'])

    raw_ipums_sample['rent_inc']  = np.where(
            raw_ipums_sample['inctot'] > 0, # has income
            100*raw_ipums_sample['rentgrs'] / (raw_ipums_sample['inctot']/12), # rent as percent of monthly income
            np.nan
    )

    raw_ipums_sample['hval_inc']  = np.where(
            raw_ipums_sample['inctot'] > 0, # has income
            raw_ipums_sample['valueh']/(raw_ipums_sample['inctot']/12), # home value as percent of monthly income
            np.nan
    )

    gap_vars = ['rentgrs', 'valueh', 'own100', 'inc_month'] # defining the variables for gap regressions
    years    = raw_ipums_sample['year'].unique()


    for v in gap_vars:
        console.print(f'Computing {v} deciles...')
        raw_ipums_sample[f'dec_{v}'] = raw_ipums_sample.groupby('year', group_keys=False).apply(
            weighted_quant_series,
            val_col = v,
            weight_col = 'hhwt',
            q = 10
        )

    raw_ipums_sample.to_parquet('/Volumes/TDP/housing_data/tab1_data.parquet')

if prepDum:

    fig2_sample = pd.read_parquet('/Volumes/TDP/housing_data/tab1_data.parquet')

    fig2_sample['asian']      = fig2_sample['raced'].between(400,679).astype(int)
    fig2_sample['chinese']    = (fig2_sample['raced'] == 400).astype(int)
    fig2_sample['japanese']   = (fig2_sample['raced'] == 500).astype(int)
    fig2_sample['filipino']   = (fig2_sample['raced'] == 600).astype(int)
    fig2_sample['indian']     = (fig2_sample['raced'] == 610).astype(int)
    fig2_sample['korean']     = (fig2_sample['raced'] == 620).astype(int)
    fig2_sample['vietnamese'] = (fig2_sample['raced'] == 640).astype(int)
    fig2_sample['thai']       = (fig2_sample['raced'] == 663).astype(int)

    races = [
        'asian',      # overall asian indicator
        'chinese',    # chinese indicator
        'japanese',   # japanese indicator
        'filipino',   # filipino indicator
        'indian',     # indian indicator
        'korean',     # korean indicator
        'vietnamese', # vietnamese indicator
        'thai'        # thai indicator
    ] # vector of race indicators for loop

    ds = fig2_sample['dec_inc_month'].dropna().unique()
    for d in ds:
        console.print(f'decile={d}')

        dummy = f'incr_d{d}'
        fig2_sample[dummy] = np.where(
            fig2_sample['dec_inc_month'].isna(),
            np.nan,
            (fig2_sample['dec_inc_month'] == d).astype(int)
        )

        for r in races:
            console.print(f'race = {r}')
            interaction = f'_ia_{r}_incr_d{d}'
            fig2_sample[interaction] = fig2_sample[r] * fig2_sample[dummy]

    fig2_sample.to_parquet('/Volumes/TDP/housing_data/tab1_reg_data.parquet')
