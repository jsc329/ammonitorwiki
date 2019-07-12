<div><img src="ammonitor-footer.png" width="1000px" align="center"></div>

-   [Chapter Introduction](#chapter-introduction)
-   [The Recordings Table](#the-recordings-table)
-   [Getting an API token for
    Dropbox](#getting-an-api-token-for-dropbox)
-   [Functions that work with
    Dropbox](#functions-that-work-with-dropbox)
-   [Downloading and viewing
    recordings](#downloading-and-viewing-recordings)
-   [Assessing the performance of equipment at active monitoring
    locations](#assessing-the-performance-of-equipment-at-active-monitoring-locations)
-   [The Recordings Table in Access](#the-recordings-table-in-access)
-   [Chapter Summary](#chapter-summary)
-   [Chapter References](#chapter-references)

Chapter Introduction
====================

This chapter covers the **recordings** table of an **AMMonitor**
database, which stores metadata about recordings. Physical recordings
themselves are stored in the **recordings** folder within the main
**AMMonitor** directory.

To begin, recall the standardized AMMonitor file directory structure. We
used the function `ammCreateDirectories()` to establish the standardized
file directory located within Dropbox. Ideally, this Dropbox account is
associated with the monitoring program and does not contain any personal
information. Below, we confirm the file structure, assuming that your
working directory is the main **AMMonitor** directory (top-level
directory):

<kbd>

<img src="Chap11_Figs/directory.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 11.1. Recordings should be placed (manually or automatically)
> into the “recording\_drop” directory. AMMonitor functions will move
> them to the more permanent “recordings” directory, and log each file’s
> metadata into the database.*

For this chapter, the directories of interest are the ‘recording\_drop’
and ‘recordings’ folders, which store audio files for acoustic
monitoring. These folders may end up storing many terabytes of data, and
this content is best left in the cloud until needed. The
‘recording\_drop’ folder is a landing folder for any new audio files
collected by the monitoring team. Audio files may be manually collected
by the monitoring team and placed there, or automatically placed in the
drop folder via the cellular network (as described in chapters 9 and 10;
see also Donovan et al. in prep).

The primary function for this chapter is `dropboxMoveBatch()`, which
searches the ‘recording\_drop’ folder on Dropbox for new files. If new
files are found, the function moves the files to the more permanent
‘recordings’ directory on Dropbox, and simultaneously records metadata
about these files to the **recordings** table of an **AMMonitor**
database. We will describe `dropboxMoveBatch()` later in the chapter.

To illustrate processes involving recordings, we will use the
`dbCreateSample()` function to create a database called “Chap11.sqlite”,
which will be stored in a folder (directory) called **database** within
the **AMMonitor** main directory (which should be your working directory
in R). Recall that `dbCreateSample()` generates all tables of an
**AMMonitor** database, and then pre-populates sample data into tables
specified by the user.

Below, we create sample data for a few necessary tables using
`dbCreateSample()`. We will auto-populate the **recordings** table with
**AMMonitor** functions later on in the chapter:

``` r
# Create a sample database for this chapter
dbCreateSample(db.name = "Chap11.sqlite", 
               file.path = paste0(getwd(),"/database"), 
               tables =  c('people', 'deployment',
                           'equipment', 'locations',
                           'accounts',  'schedule'))
```

    ## An AMMonitor database has been created with the name Chap11.sqlite which consists of the following tables:

    ## accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals

    ## 
    ## Sample data have been generated for the following tables: 
    ## accounts, people, equipment, locations, deployment, schedule

Next we connect to the database. First, we initialize a character
object, **db.path**, that holds the database’s full file path. Then, we
create a database connection object, **conx**, using RSQLite’s
`dbConnect()` function, where we identify the SQLite driver in the ‘drv’
argument, and our **db.path** object in the ‘dbname’ argument:

``` r
# Establish the database file path as db.path
db.path <- paste0(getwd(), '/database/Chap11.sqlite')

# Connect to the database
conx <- RSQLite::dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
```

Next, we send a SQL statement that will enforce foreign key constraints.

``` r
# Turn the SQLite foreign constraints on
RSQLite::dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;" )
```

    ## <SQLiteResult>
    ##   SQL  PRAGMA foreign_keys = ON;
    ##   ROWS Fetched: 0 [complete]
    ##        Changed: 0

As mentioned, we will assume that deployed equipment collects new
recordings, which are sent to the ‘recording\_drop’ directory in the
Dropbox cloud. However, our sample ‘recording\_drop’ directory has no
files in it. For the sake of illustration, we simulate this process by
reading in four wave files that come with the **AMMonitor** package. We
will write the files to the ‘recording\_drop’ directory.

``` r
# Load the recordings
data(sampleRecordings)

# Look at the structure of this object 
str(sampleRecordings, max.level = 1)
```

    ## List of 4
    ##  $ :Formal class 'Wave' [package "tuneR"] with 6 slots
    ##  $ :Formal class 'Wave' [package "tuneR"] with 6 slots
    ##  $ :Formal class 'Wave' [package "tuneR"] with 6 slots
    ##  $ :Formal class 'Wave' [package "tuneR"] with 6 slots

The recordings object is a list of four wave objects (each with six
slots) that we created with the package **tuneR** \[1\]. Below, we view
the first element in this list:

``` r
# View the first recording
sampleRecordings[[1]]
```

    ## 
    ## Wave Object
    ##  Number of Samples:      2295552
    ##  Duration (seconds):     52.05
    ##  Samplingrate (Hertz):   44100
    ##  Channels (Mono/Stereo): Mono
    ##  PCM (integer format):   TRUE
    ##  Bit (8/16/24/32/64):    16

This object is a wave file (file extension .wav). It is 52.05 seconds
long, and has a sampling rate of 44100 samples per second, with 52.05 \*
44100 = \~ 2295405 samples. The file was recorded with a single channel
microphone (mono).

Next, we pretend that these four files were collected by Middle Earth
monitoring equipment and deposited in the ‘recording\_drop’ folder in
the Dropbox cloud:

``` r
# Write these as wave files to the recording_drop folder
tuneR::writeWave(object = sampleRecordings[[1]], 
                 filename = "recording_drop/midEarth3_2016-03-12_07-00-00.wav")
tuneR::writeWave(object = sampleRecordings[[2]], 
                 filename = "recording_drop/midEarth4_2016-03-04_06-00-00.wav")
tuneR::writeWave(object = sampleRecordings[[3]], 
                 filename = "recording_drop/midEarth4_2016-03-26_07-00-00.wav")
tuneR::writeWave(object = sampleRecordings[[4]], 
                 filename = "recording_drop/midEarth5_2016-03-21_07-30-00.wav")
```

Notice that each file name is standardized as
“accountID\_date\_time.wav”. Programs that do not use smartphones as
monitoring devices can standardize file names as
“equipID\_date\_time.wav”. We have just simulated the process by which
recordings are populated into the ‘recording\_drop’ folder in your
**AMMonitor** Dropbox directory. In practice, files can be collected by
hand and manually placed in this folder, or files can be collected and
sent via the cellular network as described in previous chapters.

The next step is to move these files out of the ‘recording\_drop’
directory to the more permanent ‘recordings’ directory. During this
process, we create metadata entries in the **recordings** database table
for each recording. Logging this metadata is critical because
**AMMonitor** needs an easy way to track all audio files collected by
the monitoring team. To move files from ‘recording\_drop’ to the
‘recordings’ directory (and simultaneously log new audio file metadata
in the **recordings** table), we use the function `dropboxMoveBatch()`.

The Recordings Table
====================

Before asking `dropboxMoveBatch()` to move our four wave files to the
‘recordings’ directory, we will view a summary of the **recordings**
table using `dbTables()`:

``` r
# Look at information about the recordings table
dbTables(db.path = db.path, table = 'recordings')
```

    ## $recordings
    ##   cid        name         type notnull        dflt_value pk comment
    ## 1   0 recordingID VARCHAR(255)       1              <NA>  1        
    ## 2   1  locationID VARCHAR(255)       1              <NA>  0        
    ## 3   2 equipmentID VARCHAR(255)       1              <NA>  0        
    ## 4   3   startDate VARCHAR(255)       1              <NA>  0        
    ## 5   4   startTime VARCHAR(255)       1              <NA>  0        
    ## 6   5    filepath VARCHAR(255)       0              <NA>  0        
    ## 7   6          tz VARCHAR(255)       0              <NA>  0        
    ## 8   7      format VARCHAR(255)       0              <NA>  0        
    ## 9   8   timestamp VARCHAR(255)       1 CURRENT_TIMESTAMP  0

Foreign key assigments can be confirmed with the following code:

``` r
# Return foreign key information for the equipment table
RSQLite::dbGetQuery(conn = conx, statement = "PRAGMA foreign_key_list(recordings);")
```

    ##   id seq     table        from          to on_update on_delete match
    ## 1  0   0 equipment equipmentID equipmentID   CASCADE NO ACTION  NONE
    ## 2  1   0 locations  locationID  locationID   CASCADE NO ACTION  NONE

Here, we notice that the *equipmentID* column in the **recordings**
table maps to the *equipmentID* column in the **equipment** table, and
the *locationID* column in the **recordings** table maps to the
*locationID* column in the **locations** table.

To summarize, the **recordings** table stores information about which
wave files have been collected in an acoustic monitoring program, where
they were collected, and which piece of equipment was employed to gather
acoustic data. The table is currently empty:

``` r
# Return records in the recordings table as a tibble
RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM recordings;")
```

    ## [1] recordingID locationID  equipmentID startDate   startTime   filepath    tz          format      timestamp  
    ## <0 rows> (or 0-length row.names)

Getting an API token for Dropbox
================================

Now that we have new audio files in our ‘recording\_drop’ directory, we
can use `dropboxMoveBatch()` to move the audio files from the
‘recording\_drop’ directory to the ‘recordings’ directory.
Simultaneously, we will populate the **recordings** table.

To use `dropboxMoveBatch()`, you must allow R to connect to your
cloud-based Dropbox account, which can be accomplished using the
**rdrop2** package \[2\]. Below, we run the `drop_auth()` function and
store the output as an object called **token**.

``` r
# Load the rdrop2 package
library(rdrop2)

# Create a token that allows R to link to your Dropbox account
token <- rdrop2::drop_auth(new_user = TRUE, 
                           key = "mmhfsybffdom42w",
                           secret = "l8zeqqqgm1ne5z0", 
                           cache = TRUE, 
                           rdstoken = NA)
```

When running `drop_auth()`, a pop-up browser will prompt you to log in
to the Dropbox account that holds the **AMMonitor** directory (if you
are not already logged in). Make sure you to logged in to your AMMonitor
Dropbox account – not a personal Dropbox. The function will then ask you
to allow the **rdrop2** application to access files and folders in the
**AMMonitor** Dropbox:

<kbd>

<img src="Chap11_Figs/token-4.png" width="100%" style="display: block; margin: auto auto auto 0;" />

</kbd>

> *Figure 11.2. The R package rdrop2 can be used to let R communicate
> with your Dropbox account.*

Press the Allow button. After you have selected “Allow”, the browser
will return confirmation that authentication has been received, and you
can close the browser and return to R.

Now, navigate to the monitoring team’s Dropbox account on the web, and
click on Settings. Under the “Connected apps” tab, you should see
**rdrop2** as a linked application. As shown below, you have granted
**rdrop2** access to your full Dropbox.

<kbd>

<img src="Chap11_Figs/rdrop2.PNG" width="100%" style="display: block; margin: auto auto auto 0;" />

</kbd>

> *Figure 11.3. You will see rdrop2 listed as a connected app within
> your Dropbox account.*

Below, we view the token we created.

``` r
# Look at the structure of this object
token
```

    ## <Token>
    ## <oauth_endpoint>
    ##  authorize: https://www.dropbox.com/oauth2/authorize
    ##  access:    https://api.dropbox.com/oauth2/token
    ## <oauth_app> dropbox
    ##   key:    mmhfsybffdom42w
    ##   secret: <hidden>
    ## <credentials> access_token, token_type, uid, account_id
    ## ---

This is an object of class “Token2.0”. This object will allow you to use
R to interact with your Dropbox folder (without moving files to your
personal machine).

Next, we save this object to the **settings** directory as an RDS file,
using a meaningful name of our choice. Saving the token will allow us to
interact with Dropbox through **AMMonitor** without having to manually
authenticate and interact in a web browser each time.

``` r
saveRDS(object = token, file = 'settings/dropbox-token.RDS')
```

Note that this may not be the most secure way to interact with Dropbox.
Take precautions not to share the **AMMonitor** token with anyone
outside of your monitoring team.

Functions that work with Dropbox
================================

Your token may now be used repeatedly to interact with Dropbox through
R. We use the `readRDS()` function to read the token into R’s
environment, and then use the **rdrop2** `drop_acc()` function to return
information about our account:

``` r
library(rdrop2)

# Read in the token to R
token <- readRDS(file = 'settings/dropbox-token.RDS')

# Confirm that your dropbox account is associated with the token
account_info <- rdrop2::drop_acc(dtoken = token)

# View a few items in the account_info object
account_info['name']
```

    ## $name
    ## $name$given_name
    ## [1] "Frodo"
    ## 
    ## $name$surname
    ## [1] "Baggins"
    ## 
    ## $name$familiar_name
    ## [1] "Frodo"
    ## 
    ## $name$display_name
    ## [1] "Frodo Baggins"
    ## 
    ## $name$abbreviated_name
    ## [1] "FB"

If users have allowed **rdrop2** to link to their Dropbox folder, the
token can be used with any **rdrop2** functions to interact with files
stored in the cloud. Below, we view a list of **rdrop2** functions:

``` r
# Return the functions in rdrop2 as a data.frame
data.frame(ls("package:rdrop2"))
```

    ##      ls..package.rdrop2..
    ## 1                     %>%
    ## 2                drop_acc
    ## 3               drop_auth
    ## 4               drop_copy
    ## 5             drop_create
    ## 6             drop_delete
    ## 7                drop_dir
    ## 8           drop_download
    ## 9             drop_exists
    ## 10               drop_get
    ## 11      drop_get_metadata
    ## 12           drop_history
    ## 13 drop_list_shared_links
    ## 14             drop_media
    ## 15              drop_move
    ## 16          drop_read_csv
    ## 17            drop_search
    ## 18             drop_share
    ## 19            drop_upload

For example, if useful, we could invoke `drop_upload()` to upload our
four wave files to the ‘recording\_drop’ directory. When using
**rdrop2** functions, remember that the file path is no longer your R
working directory; it is the file path on the Dropbox cloud.

The **AMMonitor** functions `dropboxMetadata()`, `dropboxMoveBatch()`,
and `dropboxGetOneFile()` allow us to work with Dropbox cloud files
through working directory paths in R, by reading in the token stored in
the **settings** folder.

For example, the function `dropboxMetadata()` retrieves file information
for all files within a Dropbox directory; we simply need to point to our
stored token. Below, in the ‘directory’ argument, we specify the
‘recording\_drop’ directory, but this argument can take any Dropbox
directory path so long as no slashes are included at the beginning or
end of the string. In the ‘token.path’ argument, we input the path to a
Dropbox API token generated using the steps above.

``` r
meta <- dropboxMetadata(directory = 'recording_drop', 
                        token.path = 'settings/dropbox-token.RDS') 

# Look at all rows of metadata, column 'path_display'
as.data.frame(meta[,'path_display'])
```

    ##                              meta[, "path_display"]
    ## 1 /recording_drop/midEarth4_2016-03-26_07-00-00.wav
    ## 2 /recording_drop/midEarth3_2016-03-12_07-00-00.wav
    ## 3 /recording_drop/midEarth4_2016-03-04_06-00-00.wav
    ## 4 /recording_drop/midEarth5_2016-03-21_07-30-00.wav

A lot of information is passed back in the **meta** object, but we only
view the filepath on Dropbox (*path\_display*). Here, we can easily see
that there are four files in the ‘recording\_drop’ folder located in the
cloud.

The **AMMonitor** function `dropboxMetadata()` is convenient for
checking whether Dropbox files are present in a folder of choice without
having to manually log in to Dropbox.

Users will more regularly invoke the function `dropboxMoveBatch()`,
which collects Dropbox metadata, moves files from a directory of choice
to another directory of choice in Dropbox, parses information about
files, and adds metadata to the **recordings** or **photos** table.
Below, we indicate the ‘db.path’, use the ‘table’ argument to specify
that we are dealing with the database’s **recordings** table, put our
‘recording\_drop’ directory in ‘dir.from’, and our long-term storage
folder, ‘recordings’, in the ‘dir.to’ argument. Lastly, we input our
Dropbox API token in ‘token.path’.

``` r
# Move files and insert metadata to the recordings database table
dropboxMoveBatch(db.path = db.path,
                 table = 'recordings', 
                 dir.from = 'recording_drop', 
                 dir.to = 'recordings', 
                 token.path = 'settings/dropbox-token.RDS')
```

    ## Move in progress, waiting 10 seconds for server to catch up...

    ## ...Move still in progress, waiting 10 more seconds...
    ## ...Move still in progress, waiting 10 more seconds...

    ## Move status: complete

    ## Added 4 new records to recordings table.

    ##                          recordingID locationID equipmentID  startDate startTime                                      filepath                  tz
    ## 1: midEarth3_2016-03-12_07-00-00.wav location@1     equip@3 2016-03-12  07:00:00 /recordings/midEarth3_2016-03-12_07-00-00.wav America/Los_Angeles
    ## 2: midEarth4_2016-03-26_07-00-00.wav location@2     equip@4 2016-03-26  07:00:00 /recordings/midEarth4_2016-03-26_07-00-00.wav America/Los_Angeles
    ## 3: midEarth4_2016-03-04_06-00-00.wav location@2     equip@4 2016-03-04  06:00:00 /recordings/midEarth4_2016-03-04_06-00-00.wav America/Los_Angeles
    ## 4: midEarth5_2016-03-21_07-30-00.wav location@3     equip@5 2016-03-21  07:30:00 /recordings/midEarth5_2016-03-21_07-30-00.wav America/Los_Angeles
    ##    format           timestamp
    ## 1:    wav 2019-07-12 11:17:11
    ## 2:    wav 2019-07-12 11:17:11
    ## 3:    wav 2019-07-12 11:17:11
    ## 4:    wav 2019-07-12 11:17:11

The function provides feedback on the success of the move. If you like,
you can log in to Dropbox to verify that the files have been moved
automatically. Alternatively, use `dropboxMetadata()` at this stage. For
example, we can quickly check the ‘dir.to’ folder (recordings), to
confirm that recordings have been moved from the ‘recording\_drop’
folder to the ‘recordings’ folder.

``` r
# Check metadata for the directory we moved files TO 
recordings.meta <- dropboxMetadata(
  directory = 'recordings',
  token.path = 'settings/dropbox-token.RDS')
as.data.frame(recordings.meta[,'path_display'])
```

    ##               recordings.meta[, "path_display"]
    ## 1 /recordings/midEarth4_2016-03-26_07-00-00.wav
    ## 2 /recordings/midEarth3_2016-03-12_07-00-00.wav
    ## 3 /recordings/midEarth4_2016-03-04_06-00-00.wav
    ## 4 /recordings/midEarth5_2016-03-21_07-30-00.wav

A metadata check for the ‘dir.from’ folder (recording\_drop), confirms
that it now contains nothing, returning an empty list() object.

``` r
# Check metadata for the directory we moved files FROM 
recording.drop.meta <- dropboxMetadata(
  directory = 'recording_drop', 
  token.path = 'settings/dropbox-token.RDS')
```

    ## There are no files in directory "recording_drop".

``` r
recording.drop.meta
```

    ## NULL

In addition to moving files, `dropboxMoveBatch()` logs metadata in the
**recordings** table when files are moved from ‘recording\_drop’ to the
‘recordings’ directory. Below, we query the database to confirm that
metadata have been added for the four wave files:

``` r
RSQLite::dbGetQuery(conx, 'SELECT * FROM recordings')
```

    ##                         recordingID locationID equipmentID  startDate startTime                                      filepath                  tz
    ## 1 midEarth3_2016-03-12_07-00-00.wav location@1     equip@3 2016-03-12  07:00:00 /recordings/midEarth3_2016-03-12_07-00-00.wav America/Los_Angeles
    ## 2 midEarth4_2016-03-26_07-00-00.wav location@2     equip@4 2016-03-26  07:00:00 /recordings/midEarth4_2016-03-26_07-00-00.wav America/Los_Angeles
    ## 3 midEarth4_2016-03-04_06-00-00.wav location@2     equip@4 2016-03-04  06:00:00 /recordings/midEarth4_2016-03-04_06-00-00.wav America/Los_Angeles
    ## 4 midEarth5_2016-03-21_07-30-00.wav location@3     equip@5 2016-03-21  07:30:00 /recordings/midEarth5_2016-03-21_07-30-00.wav America/Los_Angeles
    ##   format           timestamp
    ## 1    wav 2019-07-12 11:17:11
    ## 2    wav 2019-07-12 11:17:11
    ## 3    wav 2019-07-12 11:17:11
    ## 4    wav 2019-07-12 11:17:11

The table contains four rows. Because we followed the instructions in
the smartphone set-up guide in Donovan et al. in prep, *recordingID* is
a unique ID that contains the *accountID* directly in the string
(e.g. midEarth4), followed by underscores that separate the recording
date (*startDate*), recording time (*startTime*), and format (*format*).
The *equipmentID*, *locationID*, *filepath*, and *tz* columns were also
auto-populated.

Downloading and viewing recordings
==================================

All recordings remain in Dropbox cloud storage until retrieved and
called into R, which we can do using `dropboxGetOneFile()`. Below, we
retrieve a wave file stored in the **recordings** folder on the cloud,
and save this file to our working directory. This action merely *copies*
the file from the cloud to a directory of choice; the file is not yet
readable by R. We put the file’s name in the ‘file’ argument, specify
‘recordings’ as the ‘directory’, and indicate the path to our Dropbox
token in ‘token.path’. Lastly, the ‘local.directory’ argument allows us
to specify where the file should land locally on our machine. Below, we
ask the file to land in our current working directory.

``` r
dropboxGetOneFile(
  file = 'midEarth4_2016-03-04_06-00-00.wav', 
  directory = 'recordings', 
  token.path = 'settings/dropbox-token.RDS', 
  local.directory = getwd())
```

    ## [1] TRUE

Next, we read the file into R’s global environment using **tuneR**’s
`readWave()` function.

``` r
# Read in this wave file into R
wav1 <- tuneR::readWave(filename = 'midEarth4_2016-03-04_06-00-00.wav')

# Show the wave file
wav1
```

    ## 
    ## Wave Object
    ##  Number of Samples:      2343936
    ##  Duration (seconds):     53.15
    ##  Samplingrate (Hertz):   44100
    ##  Channels (Mono/Stereo): Mono
    ##  PCM (integer format):   TRUE
    ##  Bit (8/16/24/32/64):    16

**wav1** is an S4 object created by **tuneR**. We will work with such
objects in depth in Chapter 13: Soundscape.

Assessing the performance of equipment at active monitoring locations
=====================================================================

If your monitoring program takes advantage of the **schedule** table,
the function `recordingsCheck()` can be used to check the number of
recordings logged in the **recordings** table against the number of
recordings that were actually *scheduled* in the **schedules** table. If
there is a mismatch – where recordings are being scheduled but not taken
– `recordingsCheck()` offers a convenient method for users to see which
equipment might need attention.

To illustrate this process, we view the scheduled recordings for our
three pieces of equipment in the sample data:

``` r
# Return the schedules table as a tibble
RSQLite::dbGetQuery(conn = conx, 
                   statement = "SELECT equipmentID,
                                       locationID, subject, startDate, startTime
                                FROM schedule
                                WHERE subject = 'recording'
                                ORDER BY locationID;")
```

    ##   equipmentID locationID   subject  startDate startTime
    ## 1     equip@3 location@1 recording 2016-03-12  07:00:00
    ## 2     equip@3 location@1 recording 2016-03-13  07:00:00
    ## 3     equip@4 location@2 recording 2016-03-04  06:00:00
    ## 4     equip@4 location@2 recording 2016-03-26  07:00:00
    ## 5     equip@5 location@3 recording 2016-03-21  07:30:00
    ## 6     equip@5 location@3 recording 2016-03-24  07:30:00
    ## 7     equip@5 location@3 recording 2016-03-24  08:00:00
    ## 8     equip@5 location@3 recording 2016-03-25  09:00:00

Notice that eight recordings were scheduled in the sample database. Two
recordings were scheduled for location@1 and location@2, while four were
scheduled for location@3. We can use `recordingsCheck()` to see if the
eight files were actually collected. The only required input to
`recordingsCheck()` is the ‘db.path’ argument. The default for
‘locationID’ argument is ‘all’, the default ‘start.date’ argument is
‘1900-01-01’, and the default ‘plot’ argument is set to TRUE.

``` r
# Return recording status
check.all <- recordingsCheck(db.path = db.path,
                             locationID = 'all',
                             plot = TRUE)
```

<img src="Chap11_Figs/unnamed-chunk-32-1.png" style="display: block; margin: auto auto auto 0;" />

Here, the bar chart shows the number of scheduled and received
recordings by date and location. The returned data.frame identifies the
*equipmentID*, *locationID*, number of scheduled events, and number of
recorded events.

``` r
check.all
```

    ##   locationID equipmentID  startDate   subject scheduled received proportion
    ## 1 location@1     equip@3 2016-03-12 recording         1        1          1
    ## 2 location@1     equip@3 2016-03-13 recording         1        0          0
    ## 3 location@2     equip@4 2016-03-04 recording         1        1          1
    ## 4 location@2     equip@4 2016-03-26 recording         1        1          1
    ## 5 location@3     equip@5 2016-03-21 recording         1        1          1
    ## 6 location@3     equip@5 2016-03-24 recording         2        0          0
    ## 7 location@3     equip@5 2016-03-25 recording         1        0          0

Alternatively, users may limit the performance summary to specific
monitoring locations (using the ‘locationID’ arugment) and start dates
(‘start.date’):

``` r
# Check schedule at location@3
check.loc3 <- recordingsCheck(db.path = db.path,
                              locationID = 'location@3',
                              plot = FALSE)
check.loc3
```

    ##   locationID equipmentID  startDate   subject scheduled received proportion
    ## 5 location@3     equip@5 2016-03-21 recording         1        1          1
    ## 6 location@3     equip@5 2016-03-24 recording         2        0          0
    ## 7 location@3     equip@5 2016-03-25 recording         1        0          0

If scheduled recordings are not arriving in Dropbox, the monitoring team
may visit and troubleshoot misbehaving equipment. Additionally, the team
may inspect smartphone logs (stored in the **logs** table and logs
folder within the **AMMonitor** directory) to discover the causes of
suboptimal equipment performance.

The Recordings Table in Access
==============================

The recordings table is a primary tab in the Access Navigation Form.

<kbd>

<img src="Chap11_Figs/recordings.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 11.4. The recordings table is populated by R. Each recording
> can be annotated, where a monitoring member labels target signals
> within a given recording, as discussed in Chapter 14.*

Notice that there are four recordings in the sample database. The ‘Hands
Off’ note indicates that recordings are logged automatically by R.
Recordings can be annotated by members of the monitoring team, in which
case a team member listens to the recording and identifies target
signals within it. Recording-specific annotations are displayed as a
table beneath each record. We will illustrate how to annotate files in
Chapter 14.

Chapter Summary
===============

In this chapter, you learned that the **AMMonitor** approach stores
recordings in the **recording\_drop** folder in the cloud. The
**AMMonitor** function `dropboxMoveBatch()` relocates files to the more
permanant **recordings** directory, and simultaneously logs metadata
entries into the database **recordings** table. This allows the
monitoring team to track all recordings within the database. Recordings
can be called into other **AMMonitor** functions for further processing.
If the **schedules** table is used to push recording schedules to each
phone’s Google calendar, `recordingsCheck()` can be used to assess phone
performance.

Chapter References
==================

1. Ligges U. TuneR: Analysis of music and speech (version 1.3.3)
\[Internet\]. Comprehensive R Archive Network; 2018. Available:
<https://cran.r-project.org/web/packages/tuneR/index.html>

2. Ram K, Yochum C. Rdrop2: Programmatic interface to the ’dropbox’ api
(version 0.8.1.9999) \[Internet\]. Comprehensive R Archive Network;
2017. Available:
<https://cran.r-project.org/web/packages/rdrop2/index.html>
