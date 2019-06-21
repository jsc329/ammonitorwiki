Chapter 19: Scripts and scriptArgs
================

  - [Scripts](#scripts)
  - [The fetchRecordings.R Script](#the-fetchrecordings.r-script)
      - [Start Script
        \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_](#start-script-__________________)
      - [End Script
        \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_](#end-script-___________________)
  - [The getSoundscape.R Script](#the-getsoundscape.r-script)
      - [Start Script
        \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_](#start-script-__________________-1)
      - [End Script
        \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_](#end-script-___________________-1)
  - [The scripts and scriptArgs table in
    Access](#the-scripts-and-scriptargs-table-in-access)
  - [Chapter Summary](#chapter-summary)
      - [Chapter References](#chapter-references)

As you’ve worked through the various chapters describing the
**AMMonitor** approach, you’ve noticed that many tables, such as
**people**, **objectives**, **equipment**, **deployment**, **acounts**,
and **locations**, are filled in manually by the monitoring team.
Entries in these tables can be manipulated in R or via the Access
front-end. However, several tables are filled in exclusively by
**AMMonitor** functions. For example, the **temporals** table is
populated by the function, `temporalsGet()`, which uses the Dark Sky API
to retrieve either forecast or historical weather conditions for
monitoring locations.

Other such examples in the **AMMonitor** workflow include:

1.  Scheduling recordings via the function, `scheduleOptim()`, which
    populates the **schedules** table.
2.  Archiving recordings and photos that were delivered into “drop”
    folders with the `dropboxMoveBatch()` function, which logs metadata
    in the **recordings** and **photos** tables.
3.  Populating the **logs** table based on files delivered to the
    “log\_drop” folder, allowing inspection of equipment performance.
4.  Documenting soundscape metrics of recordings with the function,
    `soundscape()`, which populates the **soundscape** table.
5.  Searching recordings for target signals with `scoresDetect()`, which
    populates the **scores** table.
6.  Evaluating **scores** and predicting the probability that a detected
    event is a target signal using `classifierPredict()`, which
    populates the **classifications** table.

We have provided many examples of how to use these functions in previous
chapters. Many of these tasks could be run on a daily basis, and such
tasks may be written as R scipts. For instance, a monitoring team may
follow the vignette examples and have a script that will acquire the
temporal data on a daily basis. A team may have many such scripts that
automate different tasks in **AMMonitor**.

A challenge with scripts, however, is that the arguments may change over
time. For example, the `soundscape()` function uses functions from the R
package **soundecology** \[1\], and uses the default values in
calculating metrics such as the acoustic complexity index. For example,
the default value for the FFT (Fast Fourier Transform) window in
**soundecology**’s `acoustic_complexity()` function is 512. Change this
value, and the resulting output would change. Changing this value
without documenting the change may render serious errors in an analysis
that compares acoustic complexity over time.

**AMMonitor**’s solution to the problem of changing argument inputs is
to permit the use of scripts that carry out daily tasks, but to store
the script inputs in two tables: the **scripts** table (which simply
identifies a script and its purpose), and the **scriptArgs** table. The
scripts themselves should be stored in the “scripts” directory of the
**AMMonitor** file structure:

<kbd>

<img src="Chap19_Figs/directory.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 19.1. Scripts should be stored in the scripts directory.*

We will illustrate the approach with two scripts, both of which would be
run daily (say, first thing each morning).

1.  Our first script (called “fetchRecordings.R”) will run
    `dropboxMoveBatch()` to automatically move files from the
    recording\_drop directory (where new audio files collected the
    previous day would land if monitoring via the smartphone approach)
    to the recordings directory for long-term storage, and log metadata
    in the **recordings** table. This script will be identified in the
    **scripts** table, and the arguments that feed this script will be
    stored in the **scriptArgs** table.

2.  In the second script (called “getSoundscape.R”), we will run the
    `soundscape()` function on any recordings acquired in the previous
    day. Once again, the script name and purpose will be entered in the
    **scripts** table, and the arguments that feed this script will be
    stored in the **scriptArgs** table.

To illustrate the use of scripts, along with the **scripts** and
**scriptArgs** tables in **AMMonitor**, we create sample data for a few
necessary tables using `dbCreateSample()`.

<div class="panel panel-gitlab-orange">

``` r
> # Load AMMonitor
> library(AMMonitor)
> 
> # Create a sample database for this chapter
> dbCreateSample(db.name = "Chap19.sqlite", 
+                file.path = paste0(getwd(),"/database"), 
+                tables =  c('people', 'deployment',
+                            'equipment', 'locations',
+                            'accounts', 'scripts', 
+                            'scriptArgs'))
```

    An AMMonitor database has been created with the name Chap19.sqlite which consists of the following tables: 

    accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals

``` 

Sample data have been generated for the following tables: 
accounts, people, scripts, equipment, locations, deployment, scriptArgs
```

</div>

Now, we connect to the database. First, we initialize a character
object, **db.path**, that holds the database’s full file path. Then, we
create a database connection object, **conx**, using RSQLite’s
`dbConnect()` function, where we identify the SQLite driver in the ‘drv’
argument, and our **db.path** object in the ‘dbname’ argument:

``` r
> # Establish the database file path as db.path
> db.path <- paste0(getwd(), '/database/Chap19.sqlite')
> 
> # Connect to the database
> conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
```

After that, we send a SQL statement that will enforce foreign key
constraints.

``` r
> # Turn the SQLite foreign constraints on
> dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;" )
```

    <SQLiteResult>
      SQL  PRAGMA foreign_keys = ON;
      ROWS Fetched: 0 [complete]
           Changed: 0

# Scripts

Before we begin our analysis, we view the schema of the **scripts**
table, which contains just two fields:

``` r
> # Look at information about the soundscape table
> dbTables(db.path = db.path, table = "scripts")
```

``` 
$scripts
  cid        name         type notnull dflt_value pk comment
1   0    scriptID VARCHAR(255)       1         NA  1        
2   1 description         TEXT       0         NA  0        
```

The primary key for this table is *scriptID*, which is a VARCHAR(255)
identifier, and should point to an R file located in the “scripts”
directory. The description field (TEXT) holds a full description of what
the script actually does. Below we view the records that come in the
sample dataset:

``` r
> # Use * to select all rows and columns of the scripts table
> dbGetQuery(conn = conx, statement = "SELECT * 
+                                      FROM scripts")
```

    # A tibble: 2 x 2
      scriptID        description                                                                                                                         
      <chr>           <chr>                                                                                                                               
    1 fetchRecordings This script will fetch recordings that land in the Dropbox recording_drop folder, and archive them to the Dropbox recordings folder~
    2 getSoundscape   This script will obtain soundscape metrics on new recordings given a suite of recordingIDs, and log them into the soundscape table. 

Here, we see that two scripts have been registered in this table. Thus,
we expect to see “fetchRecordings.R” and “getSoundscape.R” stored in the
“scripts” directory. (You will add these actual scripts later on in this
chapter.)

Before actually looking at the scripts, view the **scriptArgs** table
definition:

``` r
> # Look at information about the scriptArgs table
> dbTables(db.path = db.path, table = "scriptArgs")
```

``` 
$scriptArgs
  cid          name         type notnull        dflt_value pk comment
1   0      scriptID VARCHAR(255)       1              <NA>  1        
2   1          date VARCHAR(255)       1 CURRENT_TIMESTAMP  4        
3   2  functionName VARCHAR(255)       1              <NA>  2        
4   3  argumentName VARCHAR(255)       1              <NA>  3        
5   4      dataType VARCHAR(255)       0              <NA>  0        
6   5 argumentValue         TEXT       0              <NA>  0        
```

The **scriptArgs** table has 6 fields. The primary key of this table is
a composite key consisting of the fields *scriptID*, *date*,
*functionName*, and *argumentName*. The remaining fields are the
*argumentValue*, which stores the value that should be input to the
argument of the function for this record, and the *dataType*, which
stores the class or mode of the argument value.

This table stores all inputs to a given script, identifying each
function, each function argument, and each argument value. The *date*
column allows the tracking of changes in these values, thus enabling
reproducibility in the **AMMonitor** system.

# The fetchRecordings.R Script

The fetchRecordings.R script will use `dropboxMoveBatch()` to move
recordings from the **recording\_drop** folder to the **recordings**
folder, and at the same time enter metadata to the **recordings** table.
As such, we will first need to determine the inputs required by
`dropboxMoveBatch()`.

``` r
> # Return the arguments required for the dropboxMoveBatch function
> args(dropboxMoveBatch)
```

    function (db.path, table, dir.from, dir.to, token.path, wait = 10) 
    NULL

Thus, `dropboxMoveBatch()` is expecting 6 inputs; note that the ‘wait’
argument has a default value of 10. We’ll assume that the monitoring
team has logged the script’s arguments into the **scriptArgs** table.

``` r
> # Use * to select all rows and columns of the scripts table
> dbGetQuery(conn = conx, statement = "SELECT * 
+                                      FROM scriptArgs
+                                      WHERE scriptID = 'fetchRecordings' ")
```

``` 
# A tibble: 7 x 6
  scriptID        date       functionName     argumentName dataType  argumentValue               
  <chr>           <chr>      <chr>            <chr>        <chr>     <chr>                       
1 fetchRecordings 2016-11-21 dropboxMoveBatch db.path      character database/old_database.sqlite
2 fetchRecordings 2017-01-01 dropboxMoveBatch db.path      character database/Chap19.sqlite      
3 fetchRecordings 2017-01-01 dropboxMoveBatch dir.from     character recording_drop              
4 fetchRecordings 2017-01-01 dropboxMoveBatch dir.to       character recordings                  
5 fetchRecordings 2017-01-01 dropboxMoveBatch table        character recordings                  
6 fetchRecordings 2016-11-21 dropboxMoveBatch token.path   character old_token_path              
7 fetchRecordings 2017-01-01 dropboxMoveBatch token.path   character settings/dropbox-token.RDS  
```

This result shows 7 records from the **scriptArgs** table, each
referencing the *scriptID* of “fetchRecordings.” There is a single
function logged in this table, “dropboxMoveBatch”. Thus, we expect this
script to run a single function, `dropboxMoveBatch()`. The monitoring
team has decided to use the ‘wait’ default value, and has taken care to
ensure that the remaining 5 arguments and their values are present in
this table. In turn, the function requires inputs for 5 arguments
(*db.path*, *dir.from*, *dir.to*, *table*, *token.path*). However, note
that 2 of the 7 records present in the table are old, logged on
2016-11-21. The monitoring team would like the 5 most current entries to
be passed to the fetchRecordings script itself.

With this background, we can now illustrate the use of the
fetchRecordings.R script in moving files from the ‘recording\_drop’
directory to the ‘recordings’ directory. At present, no recordings have
been logged into the **recordings** table for this chapter, as confirmed
with the code below (which returns a 0 row by 9 column tibble):

``` r
> # Use * to select all rows and columns of the scripts table
> dbGetQuery(conn = conx, statement = "SELECT * 
+                                      FROM recordings")
```

    # A tibble: 0 x 9
    # ... with 9 variables: recordingID <chr>, locationID <chr>, equipmentID <chr>, startDate <chr>, startTime <chr>, filepath <chr>, tz <chr>,
    #   format <chr>, timestamp <chr>

Moreover, we have no recordings in the ‘recording\_drop’ directory, so
we have no files to move\! We will simulate this process by writing the
four wave files that come with the package’s **sampleRecordings** data
to the ‘recording\_drop’ folder. This mimics the process by which files
land in the recording\_drop directory for processing.

``` r
> # Load the recordings
> data(sampleRecordings)
> 
> # Write these as wave files to the recording_drop folder
> tuneR::writeWave(object = sampleRecordings[[1]], 
+   filename = "recording_drop/midEarth3_2016-03-12_07-00-00.wav")
> tuneR::writeWave(object = sampleRecordings[[2]], 
+   filename = "recording_drop/midEarth4_2016-03-04_06-00-00.wav")
> tuneR::writeWave(object = sampleRecordings[[3]], 
+   filename = "recording_drop/midEarth4_2016-03-26_07-00-00.wav")
> tuneR::writeWave(object = sampleRecordings[[4]], 
+   filename = "recording_drop/midEarth5_2016-03-21_07-30-00.wav")
```

Let’s assume that these recordings were collected and deposited to the
‘recording\_drop’ folder, and today the monitoring team would like to
automatically process them.

The actual fetchRecordings.R script may look something like the code
chunk below. We see the familiar database connection, foreign key
constraints, and a SQLite query that retrieves the most recent arguments
stored in the **scriptArgs** table. Note that the example below also
returns some intermediate R outputs, which are not necessary in the
script itself, but are present to illustrate what the script is actually
doing. Also note that we have commented out the database connection and
disconnection as we are already connected to this chapter’s database.

## Start Script \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

``` r
> # fetchRecordings script
> # written by Frodo Baggins
> # date: 
> 
> # Load AMMonitor
> library(AMMonitor)
> 
> # Set up database connection
> # db.path <- paste0(getwd(), '/database/Chap19.sqlite')
> 
> # Connect to the database
> # conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
> 
> # Turn the SQLite foreign constraints on
> # dbExecute(conn = conx, statement = "PRAGMA foreign_keys = ON;")
> 
> # Query to retrieve arguments from the scriptArgs table
> results <- dbGetQuery(conn = conx, statement = "
+             SELECT functionName, argumentName, 
+                    argumentValue, dataType, MAX(date) 
+             FROM scriptArgs
+             WHERE scriptID = 'fetchRecordings'
+             GROUP BY functionName, argumentName")
> 
> # Show the query results
> results
```

    # A tibble: 5 x 5
      functionName     argumentName argumentValue              dataType  `MAX(date)`
      <chr>            <chr>        <chr>                      <chr>     <chr>      
    1 dropboxMoveBatch db.path      database/Chap19.sqlite     character 2017-01-01 
    2 dropboxMoveBatch dir.from     recording_drop             character 2017-01-01 
    3 dropboxMoveBatch dir.to       recordings                 character 2017-01-01 
    4 dropboxMoveBatch table        recordings                 character 2017-01-01 
    5 dropboxMoveBatch token.path   settings/dropbox-token.RDS character 2017-01-01 

``` r
> # Extract each argument, set the R datatype, and assign as a variable to R's environment
> for (i in 1:nrow(results)) {
+ 
+   # get argument value
+   value <- results[i, 'argumentValue']
+ 
+   # get datatype
+   datatype <- results[i, 'dataType']
+ 
+   # ensure the argument value is the correct datatype
+   value <- switch(EXPR = datatype,
+                   "character" = as.character(value),
+                   "integer" = as.integer(value),
+                   "numeric" = as.numeric(value),
+                   "logical" = as.logical(value))
+   
+   # assign the value to the argumentName
+   assign(x = results[i,'argumentName'], value = value)
+ }
> 
> # Run dropboxMoveBatch; 
> # notice that all inputs originate from values in the scriptArgs table
> dropboxMoveBatch(db.path = db.path,
+                  table = table,
+                  dir.from = dir.from,
+                  dir.to = dir.to,
+                  token.path = token.path)
```

    Move in progress, waiting 10 seconds for server to catch up...

    ...Move still in progress, waiting 10 more seconds...
    ...Move still in progress, waiting 10 more seconds...

    Move status: complete

    Added 4 new records to recordings table.

    # A tibble: 4 x 9
      recordingID                  locationID equipmentID startDate  startTime filepath                            tz              format timestamp       
      <chr>                        <chr>      <chr>       <chr>      <chr>     <chr>                               <chr>           <chr>  <chr>           
    1 midEarth3_2016-03-12_07-00-~ location@1 equip@3     2016-03-12 07:00:00  /recordings/midEarth3_2016-03-12_0~ America/Los_An~ wav    2019-06-21 14:1~
    2 midEarth4_2016-03-26_07-00-~ location@2 equip@4     2016-03-26 07:00:00  /recordings/midEarth4_2016-03-26_0~ America/Los_An~ wav    2019-06-21 14:1~
    3 midEarth4_2016-03-04_06-00-~ location@2 equip@4     2016-03-04 06:00:00  /recordings/midEarth4_2016-03-04_0~ America/Los_An~ wav    2019-06-21 14:1~
    4 midEarth5_2016-03-21_07-30-~ location@3 equip@5     2016-03-21 07:30:00  /recordings/midEarth5_2016-03-21_0~ America/Los_An~ wav    2019-06-21 14:1~

``` r
> # Error checking here
> 
> # Return a message
> cat("Recordings have been moved from recording_drop to the recordings directory. Metadata have been logged into the recordings database table")
```

    Recordings have been moved from recording_drop to the recordings directory. Metadata have been logged into the recordings database table

``` r
> # Close the database connection
> # dbDisconnect(conx)
```

## End Script \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

This ends the script code; this script should be saved and stored in the
‘scripts’ directory, with inputs that point to the monitoring program’s
database. When sourced, the code will be executed with inputs stored in
the **scriptArgs** table.

We can now confirm that the metadata for these archived recordings are
now logged in the **recordings** table. Of course, we have to connect to
the database once again to continue using it\!

``` r
> # Return records in the recordings table as a tibble
> dbGetQuery(conn = conx, statement = "SELECT * FROM recordings;")
```

    # A tibble: 4 x 9
      recordingID                  locationID equipmentID startDate  startTime filepath                            tz              format timestamp       
      <chr>                        <chr>      <chr>       <chr>      <chr>     <chr>                               <chr>           <chr>  <chr>           
    1 midEarth3_2016-03-12_07-00-~ location@1 equip@3     2016-03-12 07:00:00  /recordings/midEarth3_2016-03-12_0~ America/Los_An~ wav    2019-06-21 14:1~
    2 midEarth4_2016-03-26_07-00-~ location@2 equip@4     2016-03-26 07:00:00  /recordings/midEarth4_2016-03-26_0~ America/Los_An~ wav    2019-06-21 14:1~
    3 midEarth4_2016-03-04_06-00-~ location@2 equip@4     2016-03-04 06:00:00  /recordings/midEarth4_2016-03-04_0~ America/Los_An~ wav    2019-06-21 14:1~
    4 midEarth5_2016-03-21_07-30-~ location@3 equip@5     2016-03-21 07:30:00  /recordings/midEarth5_2016-03-21_0~ America/Los_An~ wav    2019-06-21 14:1~

Thus, we’ve demonstrated that the “fetchRecordings.R” script moves
recordings from the ‘recording\_drop’ folder to the ‘recordings’ folder,
and at the same time enters metadata to the **recordings** table. Notice
that the column *timestamp* automatically registers the date on which
the function was run; we will make use of this in our next example.

# The getSoundscape.R Script

Our second example will use a script to automatically process the
soundscape data from the *new* recordings logged in the **recordings**
table. We now have four recordings to process. Before embarking on a new
script, we look at the argument inputs required by **AMMonitor**’s
`soundscape()` function:

``` r
> args(AMMonitor::soundscape)
```

    function (db.path = NULL, recordingID, token.path = "settings/dropbox-token.RDS", 
        db.insert = FALSE, ...) 
    NULL

The `soundscape()` function needs a database path, a single recordingID,
and a Dropbox token that allows us to pull a recording out of the cloud
and use it in R. The argument, ‘db.insert’, has a default of FALSE; we
will need to set this to TRUE if we want to store the output in the
**soundscape** table. The ‘dots’ argument allows us to pass in any
arguments to the R package **soundecology**’s `soundscape()` function.
Although we do not illustrate this here, it is possible to change any
arguments sent to this function by logging the change in the
**scriptArgs** table. Make sure you read the `soundscape()` helpfile\!

First, let’s see what arguments the Middle Earth monitoring team logged
in our **scriptArgs** table for the getSoundscape.R script:

``` r
> # Use * to select all rows and columns of the scripts table
> dbGetQuery(conn = conx, statement = "SELECT * 
+                                      FROM scriptArgs
+                                      WHERE scriptID = 'getSoundscape' ")
```

    # A tibble: 4 x 6
      scriptID      date       functionName          argumentName dataType  argumentValue             
      <chr>         <chr>      <chr>                 <chr>        <chr>     <chr>                     
    1 getSoundscape 2017-01-01 AMMonitor::soundscape db.insert    character TRUE                      
    2 getSoundscape 2017-01-01 AMMonitor::soundscape db.path      character database/Chap19.sqlite    
    3 getSoundscape 2017-01-01 AMMonitor::soundscape recordingID  character today                     
    4 getSoundscape 2017-01-01 AMMonitor::soundscape token.path   character settings/dropbox-token.RDS

Here, we can see that this script will use just one function, and that
is AMMonitor’s `soundscape()` function. Arguments for this script are
shown in the *argumentValue* column. Notice that argument ‘recordingID’
has been set to ‘today’ – this is not conventional; normally a
recordingID would be provided. Instead, we will write code in the script
that will retrieve all recordings that have been added to the
**recordings** table today. Recall that we just added four records to
this table.

The getSoundscape.R script will look similar to the fetchRecordings.R
script, in that we need to connect to a database, query the
**scriptArgs** table to retrieve the script inputs, and then add some
code that acquires soundscape data. Once again, the script below is
showing some intermediate R outputs that normally would not be in the
script itself (as in the first example, the intermediates R outputs are
present to show what the script is actually doing). Also note that we
have commented out the database connection and disconnection as we are
already connected to this chapter’s database.

## Start Script \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

``` r
> # fetchRecordings script
> # written by Frodo Baggins
> 
> # Load required packages
> library(AMMonitor)
> library(tuneR)
> library(soundecology)
> 
> # Set up database connection
> # db.path <- paste0(getwd(), '/database/Chap19.sqlite')
> 
> # Connect to the database
> # conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
> 
> # Turn the SQLite foreign constraints on
> # dbExecute(conn = conx, statement = "PRAGMA foreign_keys = ON;")
> 
> # Query to retrieve arguments from the scriptArgs table
> results <- dbGetQuery(conn = conx, statement = "
+             SELECT functionName, argumentName, 
+                    argumentValue, dataType, MAX(date) 
+             FROM scriptArgs
+             WHERE scriptID = 'getSoundscape'
+             GROUP BY functionName, argumentName")
> 
> # Show the query results
> results
```

    # A tibble: 4 x 5
      functionName          argumentName argumentValue              dataType  `MAX(date)`
      <chr>                 <chr>        <chr>                      <chr>     <chr>      
    1 AMMonitor::soundscape db.insert    TRUE                       character 2017-01-01 
    2 AMMonitor::soundscape db.path      database/Chap19.sqlite     character 2017-01-01 
    3 AMMonitor::soundscape recordingID  today                      character 2017-01-01 
    4 AMMonitor::soundscape token.path   settings/dropbox-token.RDS character 2017-01-01 

``` r
> # Extract each argument, set the R datatype, and assign as a variable to R's environment
> for (i in 1:nrow(results)) {
+ 
+   # get argument value
+   value <- results[i, 'argumentValue']
+ 
+   # get datatype
+   datatype <- results[i, 'dataType']
+   
+   # ensure the argument value is the correct datatype
+   value <- switch(EXPR = datatype,
+                   "character" = as.character(value),
+                   "integer" = as.integer(value),
+                   "numeric" = as.numeric(value),
+                   "logical" = as.logical(value))
+   
+   # assign the value to the argumentName
+   assign(x = results[i,'argumentName'], value = value)
+ }
> 
> 
> # Query to return all recordingID's that were logged in the recordings table today:
> recordings <- dbGetQuery(conn = conx, statement = "
+             SELECT recordingID, date(timestamp)
+             FROM recordings
+             WHERE date(timestamp) = date()
+             ")
> 
> # Show the recordings
> recordings[,1]
```

    [1] "midEarth3_2016-03-12_07-00-00.wav" "midEarth4_2016-03-26_07-00-00.wav" "midEarth4_2016-03-04_06-00-00.wav" "midEarth5_2016-03-21_07-30-00.wav"

``` r
> # Analyze soundscape
> AMMonitor::soundscape(db.path = db.path,
+          recordingID = recordings[,1],
+          token.path = token.path,
+          db.insert = db.insert)
```

``` 

 max_freq not set, using value of: 22050 


 min_freq not set, using value of: 0 


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Complexity Index (total): 1496.21


 This is a mono file.

 Calculating index. Please wait... 

  Normalized Difference Soundscape Index: 0.7136259


 This is a mono file.

 Calculating index. Please wait... 

  Bioacoustic Index: 3.462376


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Diversity Index: 2.259009

 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Evenness Index: 0.168665

 max_freq not set, using value of: 22050 


 min_freq not set, using value of: 0 


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Complexity Index (total): 1504.585


 This is a mono file.

 Calculating index. Please wait... 

  Normalized Difference Soundscape Index: 0.5666851


 This is a mono file.

 Calculating index. Please wait... 

  Bioacoustic Index: 2.155669


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Diversity Index: 2.302307

 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Evenness Index: 0.013472

 max_freq not set, using value of: 22050 


 min_freq not set, using value of: 0 


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Complexity Index (total): 1500.366


 This is a mono file.

 Calculating index. Please wait... 

  Normalized Difference Soundscape Index: 0.56092


 This is a mono file.

 Calculating index. Please wait... 

  Bioacoustic Index: 1.430398


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Diversity Index: 2.302584

 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Evenness Index: 0.000869

 max_freq not set, using value of: 22050 


 min_freq not set, using value of: 0 


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Complexity Index (total): 1506.407


 This is a mono file.

 Calculating index. Please wait... 

  Normalized Difference Soundscape Index: 0.8211343


 This is a mono file.

 Calculating index. Please wait... 

  Bioacoustic Index: 3.434104


 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Diversity Index: 2.286216

 This is a mono file.

 Calculating index. Please wait... 

  Acoustic Evenness Index: 0.103616
```

    # A tibble: 4 x 11
      recordingID                         aci  ndsi ndsi_anthrophony ndsi_biophony bioindex   adi      aei minFrq maxFrq timestamp 
      <chr>                             <dbl> <dbl>            <dbl>         <dbl>    <dbl> <dbl>    <dbl>  <dbl>  <dbl> <chr>     
    1 midEarth3_2016-03-12_07-00-00.wav 1496. 0.714            0.279          1.67     3.46  2.26 0.169         0      0 2019-06-21
    2 midEarth4_2016-03-26_07-00-00.wav 1505. 0.567            0.485          1.75     2.16  2.30 0.0135        0      0 2019-06-21
    3 midEarth4_2016-03-04_06-00-00.wav 1500. 0.561            0.621          2.21     1.43  2.30 0.000869      0      0 2019-06-21
    4 midEarth5_2016-03-21_07-30-00.wav 1506. 0.821            0.143          1.46     3.43  2.29 0.104         0      0 2019-06-21

``` r
> # Error checking here
> 
> # Return a message
> cat("Soundscape data have been processed and logged into the soundscape table of the database.")
```

    Soundscape data have been processed and logged into the soundscape table of the database.

``` r
> # Close the database connection
> # dbDisconnect(conx)
```

## End Script \_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_\_

After running this script, we should see that the files have been
analyzed, with outputs placed in the database’s **soundscape** table.

``` r
> # Check database to ensure events were added:
> RSQLite::dbGetQuery(conx, "SELECT * FROM soundscape")
```

    # A tibble: 4 x 11
      recordingID                         aci  ndsi ndsi_anthrophony ndsi_biophony bioindex   adi      aei minFrq maxFrq timestamp 
      <chr>                             <dbl> <dbl>            <dbl>         <dbl>    <dbl> <dbl>    <dbl>  <dbl>  <dbl> <chr>     
    1 midEarth3_2016-03-12_07-00-00.wav 1496. 0.714            0.279          1.67     3.46  2.26 0.169         0      0 2019-06-21
    2 midEarth4_2016-03-26_07-00-00.wav 1505. 0.567            0.485          1.75     2.16  2.30 0.0135        0      0 2019-06-21
    3 midEarth4_2016-03-04_06-00-00.wav 1500. 0.561            0.621          2.21     1.43  2.30 0.000869      0      0 2019-06-21
    4 midEarth5_2016-03-21_07-30-00.wav 1506. 0.821            0.143          1.46     3.43  2.29 0.104         0      0 2019-06-21

Here, we can see that soundscape data for our four recordings have been
entered into the **soundscape** table in the database.

Some monitoring efforts may rely on scripts heavily, and some not at
all. However, in active smartphone monitoring programs, the amount of
data that can be collected daily can be crushing, and scripts can
streamline the program’s workflow. Scripts can also be used to produce
nice markdown reports.

We envision that each monitoring team will have a unique workflow, and
the code within a collection of scripts will reflect this workflow. For
example, a team may have one giant script that connects to the database
initially, executes the code sequentially, and has a single
disconnection at the end. Alternative, a team may run several scripts in
sequence, with the first script providing the database connection, and
the last script disconnecting it. The scripts can be automatically
sourced when R is launched by sourcing these scripts upon startup, or
they can be sourced by hand.

# The scripts and scriptArgs table in Access

The scripts table is a secondary tab in the Access Navigation Form,
nestled under the ‘Mgt’ primary tab. Here’s a look at the Scripts tab,
where you can see that 2 records are stored in the sample database’s
**scripts** table. A selected script’s corresponding **scriptArgs**
information is listed as a subtable beneath it. These tables can be
sorted in a number of ways in Access to highlight arguments that will be
passed to the script.

<kbd>

<img src="Chap19_Figs/scripts.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 19.1. The scripts table stores the file names of scripts (.R
> files stored in the scripts directory), and stores all inputs to the
> script as a script argument.*

# Chapter Summary

This chapter covered the **scripts** and **scriptArgs** tables, which
provide a highly customizable means for monitoring programs to automate
repeated monitoring tasks, such as running `dropboxMoveBatch()` on a
daily basis to collect incoming recordings and log their metadata in the
**recordings** table. The **scripts** and **scriptArgs** tables track
inputs to function arguments through time to facilitate reproducibility
and sound record-keeping.

### Chapter References

<div id="refs" class="references">

<div id="ref-soundecology">

1\. Villanueva-Rivera LJ, Pijanowski BC. Soundecology: Soundscape
ecology \[Internet\]. 2018. Available:
<https://CRAN.R-project.org/package=soundecology>

</div>

</div>
