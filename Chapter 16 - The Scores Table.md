The premise of automated acoustic monitoring is that a research team can
efficiently scan new audio recordings for target signals by creating
templates, which are models of a target signal. When a template is run
against a recording, all detected signals receive a score quantifying
similarity between the signal and the template.

If a score exceeds some user-chosen score threshold, it is a “detected
event”. A detected event is a signal with some chance of being a target
signal. Some detected events may be target signals issued from a focal
species (true positives), and others may be false alarms (false
positives).

The graph below conveys the idea of pitting a recording against a
template (here, the ‘verd1’ template). The lower panel shows the match
between the template and the audio file (~24 - 51 seconds). Four
detected events exceed a user-defined threshold of 0.2. Each detected
event is highlighted in the upper panel, and these signals can be true
target signals or false alarms.

<img src="Chap16_Figs/detection-pic.png" width="600" height="400" style="display: block; margin: auto auto auto 0;" />

Given a recording and a template, this chapter highlights how to use
**AMMonitor** to obtain scores and simultaneously extract each detected
event’s acoustic *features*. Each detected event (and accompanying
acoustic features) is stored in the **scores** table, and the acoustic
features can later be used to distinguish true target signals from false
alarms (covered in Chapter 17: Classifications).

To illustrate the **scores** table, we will use `dbCreateSample()` to
create a database called “Chap16.sqlite”, to be stored in a folder
called “database” within the **AMMonitor** main directory (which should
be your working directory in R). Recall that `dbCreateSample()`
generates all tables of an **AMMonitor** database, and then
pre-populates sample data into tables specified by the user.

Below, we use `dbCreateSample()`to create sample data for necessary
tables. We will populate the **scores** table using **AMMonitor**
functions later on in the chapter.

    > # Create a sample database for this chapter
    > dbCreateSample(db.name = "Chap16.sqlite", 
    +                file.path = paste0(getwd(),"/database"), 
    +                tables = c('people', 'species','library', 
    +                           'locations','equipment', 
    +                           'accounts', 'templates', 
    +                           'recordings', 'lists', 'listItems')
    +               )

    An AMMonitor database has been created with the name Chap16.sqlite which consists of the following tables: 

    accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals


    Sample data have been generated for the following tables: 
    accounts, lists, people, species, equipment, locations, library, listItems, recordings, templates

Next, we connect to the database. First, we initialize a character
object, **db.path**, that holds the database’s full file path. Then, we
create a database connection object, **conx**, using RSQLite’s
`dbConnect()` function, where we identify the SQLite driver in the ‘drv’
argument, and our **db.path** object in the ‘dbname’ argument:

    > # Establish the database file path as db.path
    > db.path <- paste0(getwd(), '/database/Chap16.sqlite')
    > 
    > # Connect to the database
    > conx <- RSQLite::dbConnect(drv = dbDriver('SQLite'), dbname = db.path)

After that, we send a SQL statement to enforce foreign key constraints.

    > # Turn the SQLite foreign constraints on
    > RSQLite::dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;" )

    <SQLiteResult>
      SQL  PRAGMA foreign_keys = ON;
      ROWS Fetched: 0 [complete]
           Changed: 0

The Scores Table
================

We begin by viewing a summary of the **scores** table using
`dbTables()`:

    > # Look at information about the scores table
    > dbTables(db.path = db.path, table = "scores")

    $scores
       cid                  name         type notnull        dflt_value pk comment
    1    0               scoreID      INTEGER       0              <NA>  1        
    2    1           recordingID VARCHAR(255)       1              <NA>  0        
    3    2            templateID VARCHAR(255)       1              <NA>  0        
    4    3                  time         REAL       1              <NA>  0        
    5    4        scoreThreshold         REAL       0              <NA>  0        
    6    5                 score         REAL       0              <NA>  0        
    7    6 manualVerifyLibraryID      INTEGER       0              <NA>  0        
    8    7 manualVerifySpeciesID      INTEGER       0              <NA>  0        
    9    8              features         BLOB       0              <NA>  0        
    10   9             timestamp VARCHAR(255)       1 CURRENT_TIMESTAMP  0        

The primary key for this table is the *scoreID*, which is automatically
assigned by SQLite. The *recordingID* maps to a recordingID in the
**recordings** table, while the *templateID* maps to a templateID in the
**templates** table. We verify these key relationships with the
following code:

    > # Return foreign key information for the scores table
    > RSQLite::dbGetQuery(conn = conx, statement = "PRAGMA foreign_key_list(scores);")

      id seq      table        from          to on_update on_delete match
    1  0   0  templates  templateID  templateID   CASCADE NO ACTION  NONE
    2  1   0 recordings recordingID recordingID   CASCADE NO ACTION  NONE

In all cases, *on\_update* is set to CASCADE, meaning that if a key in a
primary table is updated (e.g., a templateID is updated), the changes
trickle down to the **scores** table. Notice also that *on\_delete* is
set to NO ACTION, so if a key in a primary table is deleted (e.g., a
template is deleted from the **templates** table), the change does not
affect the **scores** table. Users can choose to manually delete
affected records in the **scores** table if desired.

The **scores** table stores additional information for each detected
event from a given recording and template. The *scoreThreshold* provides
the user-defined threshold used for detecting events. The *time* field
indicates the time (in seconds) when the event was detected on the
recording. The *manualVerifyLibraryID* and *manualVerifySpeciesID*
columns will be covered in the next chapter (Classifications). The
*features* field contains acoustic summary features associated with each
detected event. Features are stored as a “blob” data type because SQlite
does not accommodate lists or S4 objects (instead, the features have
been serialized for compatibility with SQLite). Finally, the *timestamp*
field records the system date and time at which the detection was
logged.

Acquiring automatic detections with scoresDetect()
==================================================

Our task in this chapter is to illustrate the process of acquiring
automatic detections with **AMMonitor’s** `scoresDetect()` function.
Here, we pit templates that come with the sample database (see Chapter
15) against sample recordings (see Chapter 11) in search of target
signals from species of interest.

To begin, we remind ourselves that templates are stored in the
**templates** table:

    > # Retrieve the sample database templates table
    > RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM templates")

      templateID   libraryID           class software package comment   minFrq   maxFrq  wl ovlp      wn       template personID
    1      verd1 verd_2notes corTemplateList        R monitoR    <NA> 3.875977 5.943164 512    0 hanning blob[26.64 kB] fbaggins
    2      verd2  verd_other corTemplateList        R monitoR    <NA> 3.875977 5.943164 512    0 hanning blob[27.24 kB] fbaggins
    3      verd3 verd_2notes binTemplateList        R monitoR    <NA> 3.875977 5.943164 512    0 hanning blob[18.54 kB] bbaggins

Here, we see two templates of class “corTemplateList”, and one of class
“binTemplateList”. All three templates seek signals produced by the
Verdin (a songbird), with templateIDs of “verd1”, “verd2”, and “verd3”.
We would like to find instances of these signals in recordings.

To do so, we read in the recordings that come with the **AMMonitor**
package. Recall that in an established monitoring program, recordings
are wave files stored in the **recordings** directory in the cloud,
normally retrieved via `dropBoxGetOneFile()`. For the purposes of this
chapter, however, we will read in the sample recordings and write them
as waves to the working directory with **tuneR**’s \[1\] `writeWave()`
function:

    > # Read in sample recordings
    > data(sampleRecordings)
    > 
    > # Write recordings to working directory
    > tuneR::writeWave(object = sampleRecordings[[1]], 
    +                  filename = "midEarth3_2016-03-12_07-00-00.wav")
    > tuneR::writeWave(object = sampleRecordings[[2]], 
    +                  filename = "midEarth4_2016-03-04_06-00-00.wav")
    > tuneR::writeWave(object = sampleRecordings[[3]], 
    +                  filename = "midEarth4_2016-03-26_07-00-00.wav")
    > tuneR::writeWave(object = sampleRecordings[[4]], 
    +                  filename = "midEarth5_2016-03-21_07-30-00.wav")

Note that metadata for these four recordings is already tracked in the
sample **recordings** table in the database:

    > # Retrieve the sample database recordings table
    > RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM recordings")

                            recordingID locationID equipmentID  startDate startTime                                      filepath                  tz
    1 midEarth3_2016-03-12_07-00-00.wav location@1     equip@3 2016-03-12  07:00:00 /recordings/midEarth3_2016-03-12_07-00-00.wav America/Los_Angeles
    2 midEarth4_2016-03-04_06-00-00.wav location@2     equip@4 2016-03-04  06:00:00 /recordings/midEarth4_2016-03-04_06-00-00.wav America/Los_Angeles
    3 midEarth4_2016-03-26_07-00-00.wav location@2     equip@4 2016-03-26  07:00:00 /recordings/midEarth4_2016-03-26_07-00-00.wav America/Los_Angeles
    4 midEarth5_2016-03-21_07-30-00.wav location@3     equip@5 2016-03-21  07:30:00 /recordings/midEarth5_2016-03-21_07-30-00.wav America/Los_Angeles
      format           timestamp
    1    wav 2018-10-22 17:27:33
    2    wav 2018-10-22 17:27:33
    3    wav 2018-10-22 17:27:33
    4    wav 2018-10-22 17:27:33

Thus, the recordings themselves are now in our working directory as wave
files, while the recording metadata and templates are stored in the
SQLite database.

At this point, we can use `scoresDetect()` to compare template
similarity to sounds encountered in the recordings, and extract acoustic
features associated with each detected event.

This function has several arguments, many of which have default values.

    > # Retrieve the arguments for the scoresDetect function
    > args(scoresDetect)

    function (db.path, date.range, timestamp, recordingID, templateID, 
        listID, score.thresholds, directory, token.path, db.insert, 
        parallel = FALSE, show.prog = FALSE, cor.method = "pearson") 
    NULL

In brief, `scoresDetect()` requires the ‘db.path’ to the SQLite
database, the name of the ‘directory’ that holds the recordings, a
‘token.path’ if the directory is cloud-based, the names of the
‘templateIDs’ to be analyzed, the ‘score.thresholds’ to be used for
detecting events, and additional arguments that specify how the analysis
is to be conducted and how to handle the output.

There are three ways to specify which recordings should be analyzed with
`scoresDetect()`:

-   The first option is to use the ‘date.range’ argument, where a user
    must specify a length 2 character vector of date ranges (inclusive)
    over which to run template matching. Dates should be given in
    YYYY-mm-dd format. e.g. c(‘2016-03-04’, ‘2016-03-12’).
-   The second option is to use the ‘timestamp’ argument, wherein a user
    specifies a length 1 character of a date or timestamp from which to
    run the function (in YYYY-mm-dd **or** YYYY-mm-dd hh:mm:ss format).
    Here, `scoresDetect()` will be run on all recordings more recent
    than or equal to the timestamp. For example, if the ‘timestamp’ is
    set to yesterday at midnight, `scoresDetect()` will analyze any new
    recordings present in the **recordings** table beginning with
    midnight yesterday up to the present moment today. This option is
    compatible with monitoring programs that routinely analyze data as
    new material becomes available.
-   The third option is to use the ‘recordingID’ argument, where a user
    specifies a character vector of recordingIDs against which to run
    templates. If scores should be run for all recordings, the user may
    set recordingID = ‘all’.

Similarly, there are two ways to specify which templates should be
analyzed in the `scoresDetect()` function.

-   First, the user can pass in a vector of templateIDs from the
    **templates** table.
-   Second, the user can provide a *listID* from the **listItems**
    table, and store the template names as a database list. For example,
    the sample database contains a list called “Target Species
    Templates”, which contains the *items* ‘verd1’ and ‘verd2’ from the
    **templates** table, column *templateID*. We can confirm this with
    the following query:

<!-- -->

    > # Retrieve a list called 'Target Species Templates'
    > RSQLite::dbGetQuery(conn = conx, 
    +                     statement = "SELECT * 
    +                                  FROM listItems 
    +                                  WHERE listID = 'Target Species Templates' ")

                        listID   dbTable   dbColumn  item
    1 Target Species Templates templates templateID verd1
    2 Target Species Templates templates templateID verd2

Thus, an **AMMonitor list** can be passed to `scoresDetect()` function
in lieu of a vector of templateIDs.

Finally, there are alternative approaches for specifying the score
thresholds to be used by the `scoresDetect()` function. First, the user
can pass in a vector of score thresholds used. In this case, the
threshold values should be ordered by the template order. Second, if the
user provides no threshold values, `scoresDetect()` will utilize the
score threshold value stored with the template directly via monitoR
functions (see Chapter 15); **be aware that monitoR uses default values
for score thresholds if you do not provide them yourself when creating
the template**.

We illustrate some alternative approaches in the three code blocks
below. In all cases, we are pitting templates against the recordings
‘midEarth3\_2016-03-12\_07-00-00’, ‘midEarth4\_2016-03-04\_06-00-00’,
‘midEarth4\_2016-03-26\_07-00-00’, and ‘midEarth5\_2016-03-21\_07-30-00’
(located in the working directory). Here, the Chap16 database is
identified in the *db.path* argument, and the recordings are located in
our working directory. For the ‘score.thresholds’ argument, we specify a
numeric vector of score thresholds to use for each template; any signal
above this threshold will be registered as a detected event. Lastly, we
indicate whether we want to insert the scores directly into the database
(db.insert = TRUE) or merely test the function while learning how to use
it (db.insert = FALSE).

    > # Run scoresDetect using recordingID = 'all' and a vector of templateIDs
    > # Example is not executed
    > scores <- scoresDetect(db.path = db.path, 
    +                        directory = getwd(), 
    +                        recordingID = 'all',
    +                        templateID = c('verd1', 'verd2', 'verd3'),
    +                        score.thresholds = c(0.2, 0.2, 13),
    +                        token.path = NULL, 
    +                        db.insert = FALSE)

    > # Run scoresDetect using a listID for templates, 
    > # a timestamp for recordings, and omitting the score.thresholds argument 
    > # Example is not executed
    > scores <- scoresDetect(db.path = db.path, 
    +                        directory = getwd(), 
    +                        timestamp = '2018-10-21',  
    +                        listID = 'Target Species Templates',     
    +                        token.path = NULL, 
    +                        db.insert = FALSE) 

    > # Run scoresDetect using a listID for templates and a 
    > # date.range for recordings; insert to database
    > # This example IS executed and we insert results into the database
    > scores <- scoresDetect(db.path = db.path, 
    +                        directory = getwd(), 
    +                        date.range = c('2016-03-04', '2016-03-12'),  
    +                        listID = 'Target Species Templates',     
    +                        score.thresholds = c(0.2, 0.2),
    +                        token.path = NULL, 
    +                        db.insert = TRUE) 

    Reading wave for spectrogram parameter set 1, recording 1 out of 2

    Processing scores for template 1 (verd1)

    Processing scores for template 2 (verd2)

    Reading wave for spectrogram parameter set 1, recording 2 out of 2

    Processing scores for template 1 (verd1)

    Processing scores for template 2 (verd2)

    New scores added to database

As shown, `scoresDetect()` generates a number of progress messages about
which recordings and templates it is currently processing (all of which
may be suppressed by wrapping the function in a call to
`suppressMessages()`). If we have previously run the same combination of
recordingID, templateID and score threshold and these records are
present in the database, the function will neither run nor insert this
combination again.

The results of `scoresDetect()` are provided in a data frame, which is
inserted into the database **scores** table if db.insert = TRUE. Below,
we view the first six scores from our analysis:

    > # Retrieve a scores from the 'verd1' template
    > RSQLite::dbGetQuery(conn = conx, 
    +                     statement = "SELECT * 
    +                                  FROM scores 
    +                                  WHERE templateID = 'verd1' LIMIT 6")

      scoreID                       recordingID templateID      time scoreThreshold     score manualVerifyLibraryID manualVerifySpeciesID       features
    1       1 midEarth3_2016-03-12_07-00-00.wav      verd1  0.499229            0.2 0.2669258                    NA                    NA blob[37.23 kB]
    2       2 midEarth3_2016-03-12_07-00-00.wav      verd1  2.066576            0.2 0.2529111                    NA                    NA blob[37.23 kB]
    3       3 midEarth3_2016-03-12_07-00-00.wav      verd1  3.308844            0.2 0.2538855                    NA                    NA blob[37.23 kB]
    4       4 midEarth3_2016-03-12_07-00-00.wav      verd1  8.695873            0.2 0.2049214                    NA                    NA blob[37.23 kB]
    5       5 midEarth3_2016-03-12_07-00-00.wav      verd1 10.692789            0.2 0.2506303                    NA                    NA blob[37.23 kB]
    6       6 midEarth3_2016-03-12_07-00-00.wav      verd1 13.920363            0.2 0.3788103                    NA                    NA blob[37.23 kB]
                timestamp
    1 2019-06-21 12:47:35
    2 2019-06-21 12:47:35
    3 2019-06-21 12:47:35
    4 2019-06-21 12:47:35
    5 2019-06-21 12:47:35
    6 2019-06-21 12:47:35

Notice that the first detected event in the recording
midEarth3\_2016-03-12\_07-00-00.wav was produced by the template
“verd1”. This signal was detected at time 0.499 seconds, and had a score
of 0.267. This score was added to the results because it exceeded the
threshold of 0.2, which is also stored in the database.

The columns *manualVerifyLibraryID* and *manualVerifySpeciesID* will be
filled in later (See Chapter 17: Classifications). The features of each
event are stored in the database as a “blob” datatype, which is
displaying as “raw 37.41 kB”.

Event Features
==============

To explore detected event features in greater depth, we query the
database and extract the first record from the **scores** table:

    > # Retrieve a scores from the 'verd1' template
    > scores <- RSQLite::dbGetQuery(conn = conx, 
    +                               statement = "SELECT * 
    +                                            FROM scores 
    +                                            WHERE templateID = 'verd1' LIMIT 1")
    > 
    > # Look at the structure
    > str(scores)

    'data.frame':   1 obs. of  10 variables:
     $ scoreID              : int 1
     $ recordingID          : chr "midEarth3_2016-03-12_07-00-00.wav"
     $ templateID           : chr "verd1"
     $ time                 : num 0.499
     $ scoreThreshold       : num 0.2
     $ score                : num 0.267
     $ manualVerifyLibraryID: int NA
     $ manualVerifySpeciesID: int NA
     $ features             :List of 1
      ..$ : raw  58 0a 00 00 ...
      ..- attr(*, "class")= chr "blob"
     $ timestamp            : chr "2019-06-21 12:47:35"

Here, we confirm the returned object is a data.frame. *Features* of each
event are returned as a list of 1, and are of serialized “raw” data
type. We use `unserialize()` to unserialize the features into their
original state and see what they are:

    > # Unserialize event features
    > unserialized.features <- lapply(X = scores$features, FUN = 'unserialize')

The **unserialized.features** object is still a list, but the features
are now contained in a data.frame.

    > # Confirm that features of an event are stored as a data.frame within a list
    > class(unserialized.features[[1]])

    [1] "data.frame"

    > # Get dimensions of this dataframe
    > dim(unserialized.features[[1]])

    [1]    1 1205

The **unserialized.features** object contains a wealth of data about the
detected event, stored as a single row with 1204 columns.
`scoresDetect()` depends heavily on the sound analysis R package
**seewave** \[2\] to acquire these acoustic features. We will use this
collection of numbers in the next chapter to train models that fine-tune
the automated detection system, distinguishing target signals from false
alarms.

Below, we view features 1 through 10 of this event to get an idea of
what they are:

    > # Extract row 1, columns 1:10 from this features dataframe
    > unserialized.features[[1]][1,1:10]

          amp.1     amp.2     amp.3     amp.4     amp.5     amp.6     amp.7     amp.8     amp.9    amp.10
    1 -33.01125 -37.86813 -37.77042 -39.83472 -40.65963 -45.24885 -46.19274 -42.20982 -53.56204 -44.39047

These particular features constitute the first through the tenth
amplitude values associated with the detected event, designated by the
prefix **amp**. They represent the magnitude of the first 10 pixels of
the spectrogram. The total number of **amp** values in a feature set
depends on the size of the template.

Features that begin with a prefix of **tc** or **fc** were generated by
the package **seewave**’s `acoustat()` function. `acoustat()` computes
the short-term Fourier transform (STFT) to produce a time by frequency
matrix, and then computes an aggregation function across rows and
columns of the matrix, giving the time and frequency contours. [From the
`acoustat()`
helpfile](http://rug.mnhn.fr/seewave/HTML/MAN/acoustat.html), “each
contour is considered as a probability mass function (PMF) and
transformed into a cumulated distribution function (CDF).”

The number of **tc** values is equal to the number of time bins in the
template. Each **tc** value is the amplitude probability mass function
for that time bin:

    > # Extract row 1, columns 1076:1085 from this features dataframe
    > unserialized.features[[1]][1,1076:1085]

            tc.1       tc.2      tc.3       tc.4       tc.5       tc.6       tc.7       tc.8       tc.9      tc.10
    1 0.01444347 0.01859349 0.1005136 0.06803738 0.05429053 0.04760311 0.06306978 0.04284495 0.03080277 0.03530744

Features that begin with the prefix **fc** were also generated by
**seewave’s** `acoustat()`. The number of **fc** values is equal to the
number of frequency bins in the template. Each **fc** value is the
amplitude probability mass for that frequency bin:

    > # Extract row 1, columns 1118:1127 from this features data.frame
    > unserialized.features[[1]][1,1118:1127]

            fc.1       fc.2       fc.3       fc.4       fc.5       fc.6      fc.7       fc.8       fc.9      fc.10
    1 0.02424109 0.02433052 0.02371361 0.02805763 0.02768594 0.03246467 0.0326997 0.03128434 0.03464368 0.04176078

Features with a **time** prefix were also generated by **seewave’s**
`acoustats()` function, and are calculated from the cumulative
distribution functions generated from the time probability mass function
(time.P1 = time initial percentile; time.M = time median; time.P2 = the
time terminal percentile; time.IPR = time interpercentile range):

    > # Extract row 1, columns whose name includes 'time'
    > unserialized.features[[1]][1, grep(pattern = 'time', names(unserialized.features[[1]]))]

        time.P1   time.M   time.P2  time.IPR
    1 0.0237874 0.118937 0.4519606 0.4281732

Features with a **freq** prefix were also generated by **seewave’s**
`acoustats()` function, and are calculated from the cumulative
distribution functions generated from the frequency probability mass
function (freq.M = freq median; freq.P2 = the freq terminal percentile;
freq.IPR = freq interpercentile range). ‘freq.p1’, or the frequency
initial percentile, is calculated by `acoustats()` but is not stored in
the feature set because it is the same for each detected event from a
given template, and therefore has no use for distinguishing between
target signals and false alarms.

    > # Extract row 1, columns whose name includes 'freq'
    > unserialized.features[[1]][1, grep(pattern = 'freq', names(unserialized.features[[1]]))]

        freq.M  freq.P2 freq.IPR
    1 5.081836 5.857031 1.808789

Features with the prefix **sp** were calculated via the **seewave**
`specprop()` function, which returns a list of statistical properties of
a frequency spectrum (sp.mean = mean frequency of the amplitude matrix;
sp.sd = sd of the mean of the amplitude matrix; sp.sem = standard error
of the mean of the amplitude matrix; sp.median = median frequency of the
amp matrix; sp.mode = mode frequency (dominant frequency) of the amp
matrix; sp.Q25 = first quartile; sp.Q75 = third quartile; sp.IQR =
interquartile range; sp.cent = centroid of the amp matrix; sp.skewness =
skewness; sp.kurtosis = kurtosis (“peakedness”); sp.sfm = spectral
flatness measure; sp.sh = spectrol entropy):

    > # Extract row 1, columns whose name includes 'sp'
    > unserialized.features[[1]][1, grep(pattern = 'sp', names(unserialized.features[[1]]))]

       sp.mean     sp.sd sp.median    sp.sem sp.mode   sp.Q25 sp.Q75    sp.IQR  sp.cent  sp.skewness sp.kurtosis       sp.sfm        sp.sh
    1 5.042778 0.5846285  5.081836 0.1169257 4.90957 4.565039 5.5125 0.9474609 5.042778 0.0005244409 0.002197706 0.0009582168 0.0009867879

Finally, features preceded by **zc** were acquired via **seewave**’s
`zcr()` function, and reflect zero-crossing rates. A zero-crossing rate
is the average number that the sign of a time wave changes within a
given time bin. Because the template associated with these features has
42 time bins, there are 42 zero-crossing rate values:

    > # Extract row 1, columns 1163:1172 from this features dataframe
    > unserialized.features[[1]][1, 1163:1172]

          zc.1      zc.2      zc.3      zc.4      zc.5      zc.6      zc.7      zc.8      zc.9     zc.10
    1 0.234375 0.2382812 0.2539062 0.2421875 0.2304688 0.2304688 0.2460938 0.2265625 0.2148438 0.2226562

As previously noted, the features for each detected event will be used
in our next chapter, 17: Classifications, where they can be used to
separate true positive events from false alarms.

The Scores Table in Access
==========================

The scores table is a secondary tab in the Access Navigation Form,
located under the ‘Recordings’ primary tab. Below, we view the
Recordings tab, where you can see four recordings are present in the
database, and annotations are listed for each recording.

<kbd>

<img src="Chap16_Figs/recordings.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 16.1. The Recordings primary tab shows each recording and any
> associated annotations.*

Clicking on the secondary tab labeled “Scores” will bring up the scores
themselves.

<kbd>

<img src="Chap16_Figs/scores.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 16.2. Each score is an event that was detected by AMMonitor.
> This event is identified with a particular recordingID and timestamp.
> The registered event may be a true positive event, in which the signal
> is the signal you seek, or it may be a false alarm, in which it is not
> the signal you seek. Each score can be assigned a probability that it
> is the signal you seek, as described in Chapter 17*.

Each score is listed individually (here, we are viewing the first of 52
scores in the database). The “Hands Off!” message reiterates that these
entries are filled in automatically by the `scoresDetect()` function,
not entered manually. Each score can be manually verified, and
additionally run through sets of statistical learning classifiers that
return the probability that the signal is a target signal. These topics
are covered in the Classifications chapter (next).

Chapter Summary
===============

This chapter covered the **scores** table, which stores events detected
by templates that seek target signals within audio recordings. Detected
events are acquired via `scoresDetect()`, which runs template matching
functions and also extracts acoustic features associated with each
detected event. These features contain a rich amount of information
about each detected signal, which can be used to help the computer
separate target signals from false alarms.

Chapter References
==================

1. Ligges U. TuneR: Analysis of music and speech (version 1.3.3)
\[Internet\]. Comprehensive R Archive Network; 2018. Available:
<https://cran.r-project.org/web/packages/tuneR/index.html>

2. Sueur J, Aubin T, Simonis C. Seewave: Sound analysis and synthesis
(version 2.1.0) \[Internet\]. Comprehensive R Archive Network; 2018.
Available: <https://cran.r-project.org/web/packages/seewave/index.html>
