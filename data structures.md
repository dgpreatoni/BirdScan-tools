# Data Structures
What follows is a rather mixed up list of possible data structures, as already present in [Birdscan_RTools](https://github.com/BirdScanCommunity/BirdScan_RTools), but with all the modifications (backward compatible!) needed to be as fast, platform-indpeendent and re-usable as possible.

## Basic data container
As per the `extractDBData()` function, data pulled from the BirdScan M1 MSSQL database are stored in R as a list od dataframes:
```
list(echoData = echoData, 
     protocolData = protocolData,
     siteData = siteData, 
     visibilityData = visibilityData,
     timeBinData = timeBinData,
     availableClasses = availableClasses,
     rfFeatures = rfFeatures,
     classProbabilitiesAndMtrFactors = classProbabilitiesAndMtrFactors)
```
The `extractDBData()` function by default tries to load data from a file named `DB_Data_<dbName>.Rdata` in the `dbDataDir` directory.
