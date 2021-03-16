#### BirdScan-tools
Convenience software tools for Swiss BirdRadar BirdScanM1

This is a (presently rather loose) collection of scripts, how-to documents and procedures used to handle both the Swiss BirdRadar BirdScan M1 #270 hardware and the local copy of its MSSQL database.

## The set-up
The Birdscan operates remotely and is connected only via cellular phone network (3G/4G). As a direct realtime access to the database is impossible, the workflow is as follows:

- periodically (monthly) an operator connects via TeamViewer to the remote BirdScan, and follows the procedure to siart a backup lf the Microsoft SQL server running on the radar itself.
- after some minutes (a backup takes on the average half an hour or less), the operator re-connects to the remote BirdScan and downloads the backup file.
- At my lab, an Ubuntu Linux server runs a Developer Edition of MS SQL Server, no which the backup is restored.
- a series of R scripts connect to that server and "consume" data, either for analysis or for interactive data exploration.


