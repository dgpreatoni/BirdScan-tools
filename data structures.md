# Data Structures
What follows is a rather mixed up list of data structures, as already present in [Birdscan_RTools](https://github.com/BirdScanCommunity/BirdScan_RTools), but with all the modifications (backward compatible!) needed to be as fast, platform-indpeendent and re-usable as possible.

## Basic data container
As per the `extractDBData()` function, data pulled from the BirdScan M1 MSSQL database are stored in R as a list of dataframes:
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
Database connection thus must be explicitly asked for (specifying `forceToExtractDataFromDatabase==TRUE` in the `extractDBData()` call.
This is handy, since it is faster and makes it possible to work uncoupled from the database server, and also allows having data coming from more than a single database.

