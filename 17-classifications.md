<div><img src="ammonitor-footer.png" width="1000px" align="center"></div>

  - [Chapter Introduction](#chapter-introduction)
  - [The Classifications Table](#the-classifications-table)
  - [Verifying detections with
    scoresVerify()](#verifying-detections-with-scoresverify)
  - [Training and testing classifiers using
    classifierModels()](#training-and-testing-classifiers-using-classifiermodels)
  - [Making predictions on new data using
    classifierPredict()](#making-predictions-on-new-data-using-classifierpredict)
  - [Creating Ensemble Predictions](#creating-ensemble-predictions)
  - [The Classifications Table in
    Access](#the-classifications-table-in-access)
  - [Chapter Summary](#chapter-summary)
  - [Chapter References](#chapter-references)

# Chapter Introduction

The previous chapter (16: The Scores Table) illustrated how to use
templates to search recordings for target signals, which produces
detected events that exceed a user-chosen score threshold. Detected
events are tracked in the database **scores** table. For each detected
event, the **AMMonitor** system will also extract associated acoustic
features. Some of the detected events may be target signals issued from
a focal species, and others may be false alarms that were acoustically
similar enough to the template to produce a detection.

This chapter demonstrates how acoustic features stored in the **scores**
table can be used to create classification models that are able to
separate template-detected events into target signals and false alarms
\[1\]. Once these classifiers are created and tested, they can be stored
in an AMModel library for future use. For example, as templates are run
against new recordings, the classification models take the raw scores
generated from `scoresDetect()` and return the probability that each
detected event is a target signal. These probabilities are stored in the
**classifications** database table, which can be used in downstream
analyses such as an occupancy analysis (Chapter 18: Analyses).

To illustrate the process of generating **classifications**, we will use
`dbCreateSample()` to create a database called “Chap17.sqlite”, which
will be stored in a folder (directory) called **database** within the
**AMMonitor** main directory, which should be your working directory in
R. Recall that `dbCreateSample()` generates all tables of an
**AMMonitor** database, and then pre-populates sample data into tables
specified by the user.

Here, we create sample data for several necessary tables using the
`dbCreateSample()` function below. We will view classifications that
come with the sample database, and will additionally auto-populate the
**classifications** table with **AMMonitor** functions later on in the
chapter:

``` r
# Create a sample database for this chapter
dbCreateSample(db.name = "Chap17.sqlite", 
               file.path = paste0(getwd(),"/database"), 
               tables = c('accounts', 'lists', 'people', 'species', 
                          'equipment', 'locations', 'library', 'listItems',
                          'recordings', 'templates', 'scores', 'classifications'))
```

    ## An AMMonitor database has been created with the name Chap17.sqlite which consists of the following tables:

    ## accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals

    ## 
    ## Sample data have been generated for the following tables: 
    ## accounts, lists, people, species, equipment, locations, library, listItems, recordings, templates, scores, classifications

Now, we connect to the database. First, we initialize a character
object, **db.path**, that holds the database’s full file path. Then, we
create a database connection object, **conx**, using RSQLite’s
`dbConnect()` function, where we identify the SQLite driver in the ‘drv’
argument, and our **db.path** object in the ‘dbname’ argument:

``` r
# Establish the database file path as db.path
db.path <- paste0(getwd(), '/database/Chap17.sqlite')

# Connect to the database
conx <- RSQLite::dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
```

After that, we send a SQL statement that will enforce foreign key
constraints.

``` r
# Turn the SQLite foreign constraints on
RSQLite::dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;" )
```

    ## <SQLiteResult>
    ##   SQL  PRAGMA foreign_keys = ON;
    ##   ROWS Fetched: 0 [complete]
    ##        Changed: 0

# The Classifications Table

We begin by looking at the **classifications** table, the subject of
this chapter. We can use the `dbTables()` function to look at the
table’s field summary:

``` r
# Look at information about the table
dbTables(db.path = db.path, table = "classifications")
```

    ## $classifications
    ##   cid             name         type notnull        dflt_value pk comment
    ## 1   0          scoreID      INTEGER       1              <NA>  1        
    ## 2   1             amml VARCHAR(255)       0              <NA>  2        
    ## 3   2       classifier VARCHAR(255)       0              <NA>  0        
    ## 4   3        modelName VARCHAR(255)       0              <NA>  3        
    ## 5   4 modelProbability         REAL       0              <NA>  0        
    ## 6   5        timestamp VARCHAR(255)       1 CURRENT_TIMESTAMP  0

Each record in the **classifications** table constitutes a detected
event, identified by a *scoreID*. The column *modelProbability* is the
probability that event is a target signal (true positive) from a given
classification approach, identified by the column *classifier*. The
classification model itself is stored in an AMModel library (*amml*)
with a given model name (*modelName*). Finally, we keep track of when
the prediction was made using a *timestamp*. The *scoreID*, *amml*, and
*modelName* columns together constitute the primary key for this table.

As is true for all tables, foreign key assigments can be confirmed using
the PRAGMA statement below:

``` r
# Return foreign key information for the classifications table
RSQLite::dbGetQuery(conn = conx, statement = "PRAGMA foreign_key_list(classifications);")
```

    ##   id seq  table    from      to on_update on_delete match
    ## 1  0   0 scores scoreID scoreID NO ACTION NO ACTION  NONE

There is only one foreign key in this table (*scoreID*), which
references *scoreID* in the table **scores**. Recall that each record in
the **scores** table is a detected event, and the features associated
with that event are stored in the table directly. Notice that
*on\_update* is set to NO ACTION, meaning that if a key in the
**scores** primary table is updated (e.g., the scoreID name is updated),
the changes do NOT trickle down to the **classifications** table. This
is not the typical AMMonitor database action: since scoreID names are
numbers generated automatically, they should never be changing, so no
cascading is necessary. Notice also that *on\_delete* is set to NO
ACTION, so if a *scoreID* in the **scores** table is deleted, the change
does not affect the **classifications** table. Users can choose to
manually delete affected records in the **classifications** table if
they wish.

To get an idea of what the **classifications** table holds, we view
records for a single event (scoreID = 1) in the sample
**classifications** table. We will illustrate how these records were
added later in the chapter:

``` r
# Retrieve the database classifications for scoreID = 1
classifications <- RSQLite::dbGetQuery(conn = conx, 
                                       statement = "SELECT * 
                                                    FROM classifications 
                                                    WHERE scoreID = 1")

# View the classification data for scoreID 1
classifications
```

    ##   scoreID        amml classifier                     modelName modelProbability           timestamp
    ## 1       1 classifiers     glmnet    verd1_0.2_libraryID_glmnet       0.17018835 2019-01-26 18:05:14
    ## 2       1 classifiers       kknn      verd1_0.2_libraryID_kknn       0.00000000 2019-01-26 18:05:16
    ## 3       1 classifiers         rf        verd1_0.2_libraryID_rf       0.33000000 2019-01-26 18:05:15
    ## 4       1 classifiers  svmLinear verd1_0.2_libraryID_svmLinear       0.08530979 2019-01-26 18:05:15
    ## 5       1 classifiers  svmRadial verd1_0.2_libraryID_svmRadial       0.61615217 2019-01-26 18:05:14

The five records returned show predictions for *scoreID* number 1. The
type of *classifier* in **AMMonitor** is currently limited to ‘glmnet’,
‘svmRadial’, ‘svmLinear’, ‘rf’, and ‘kknn’, which we define later. The
*modelName* describes the name of the classifier model stored in an
AMModel library (*amml*) called “classifiers”. Here, you can see five
different classification models have been used to obtain the probability
that scoreID 1 is a target signal (e.g., verd1\_0.2\_libraryID\_glmnet).
Notice that each classifier generates its own prediction about the
target signal probability for this *scoreID*: glmnet predicts a 0.170
probability that *scoreID* 1 is a target signal, while svmRadial
predicts 0.616. Additionally, svmLinear (0.0853), rf (0.330), and kknn
(0.00) each make their own predictions. The process repeats for all
*scoreID*s in the **classifications** table.

To generate the content stored in the **classifications** table, the
**AMMonitor** user must:

1.  *Verify* a subset of detected events in the **scores** table,
    labeling them as target signals or false alarms.
2.  Use the verified events to create a classification model (e.g.,
    k-nearest neighbors), and store the resulting trained model in an
    AMModels library.
3.  Use a trained classifier model to make predictions on new data, and
    insert records into the **classifications** table.

The rest of the chapter is devoted to illustrating how **AMMonitor**
functions are used to accomplish these tasks. We will train a suite of
statistical learning classifiers to discriminate between target signals
(in this case, two-note Verdin calls) and false alarms (in this case,
any detection that is not a two-note Verdin call). The two-note Verdin
call is represented by the *templateID* ‘verd1’.

We proceed using the following steps:

1.  **Create labeled training data (“verifications”).** Users begin by
    verifying some number of detected events registered in the
    **scores** table. This means that a human manually examines a subset
    of events, and indicates whether each event is the target or not.
    The verifications themselves are stored directly in the **scores**
    table. This process is known as “labeling the data”, and is needed
    for classifier training and testing. Typically, the more
    verifications, the better; a verified data set that contains at
    least 50 target signal examples and at least 50 false alarm examples
    would be ideal, though this is merely a rule of thumb and depends on
    various factors, such as acoustic qualities of the target signals
    and features of the research soundscape. The number of verifications
    users can acquire will depend both on the availability of the target
    signal in the research soundscape and the amount of personnel time
    put toward manual verifications. Other considerations abound, and
    research programs should develop their own labeling standards for
    target signals vs. false alarms. Depending on the amount of
    individual and/or intraspecific variation present in target signals,
    researchers may wish to ensure that verifications comprise a
    stratified sample that reflects variation in sampling sites and
    times of day to protect against the classification system being
    inadvertently trained on only a few individual members of a given
    species.

2.  **Train and test classifiers.** Next, verifications are split into
    “training” and “testing” data. Typically, 60-90% of the verified
    data will be used for training, and the remaining 10-40% will be
    used for testing. Sometimes, verification datasets will contain a
    class imbalance, wherein there are many more target signals than
    false alarms, or vice versa. If so, it is ideal to split the data
    such that this class imbalance is preserved in both the training and
    testing data. </br></br>Once the data have been split into training
    and testing datasets, we pass the training dataset to a suite of
    statistical learning classifiers (also known as machine learning
    classifiers). For the statistical learning algorithms themselves,
    **AMMonitor** depends entirely on the R package
    [caret](http://topepo.github.io/caret/index.html) \[2\], which
    stands for **c**lassification **a**nd **re**gression **t**raining.
    **AMMonitor** currently uses five classifiers from the **caret**
    package: regularized logistic regression (‘glmnet’), random forests
    (‘rf’), kernelized k-nearest neighbors (‘kknn’), and two types of
    support vector machine, radial and linear (‘svmRadial’,
    ‘svmLinear’). Each of the five classifiers is trained on the
    training data using a default of repeated 10-fold cross validation.
    All five classification algorithms fit models that map acoustic
    features (the *features* column of the **scores** table, described
    in Chapter 16) to the labeled outputs (target signal or false alarm)
    in the verification data. Thus, we seek acoustic features that can
    descriminate between target signals and false alarms. Each algorithm
    produces a probability that a given detection is a target signal.
    </br></br> After all five classifiers have been trained on the
    training data, they are tested on the “test” data withheld during
    the training phase. We then assess the performance of all
    classifiers based on the predictions they make about the test data,
    and make adjustments as needed. This process may take a few
    iterations of testing before the researcher is satisfied with a
    final classifier model.

3.  **Use trained classifiers to make predictions on new data.** Once
    classifiers have been trained and sufficiently tuned, one or more
    classifiers may be released “into the wild” and used to make
    predictions on new incoming data (new records in the **scores**
    table). At this stage, classifications may be stored in the
    **classifications** table, where each *scoreID* is associated with
    an *amml*, *classifier*, *modelName*, and *modelProbability* that
    the detected event is truly a target signal.

Below, we detail all three steps using **AMMonitor** functions and
illustrate how the sample database **classifications** records were
created for scores associated with the template ‘verd1’.

# Verifying detections with scoresVerify()

The first step toward creating classifiers that assign a target signal
probability to each detected event is to verify some of the detections
(“scores”) generated by `scoresDetect()`, as described in the previous
chapter.

``` r
# Retrieve the database scores associated with the verd1 template
verd1.scores <- RSQLite::dbGetQuery(conn = conx, 
                                    statement = "SELECT * FROM scores
                                                 WHERE templateID = 'verd1' ")

# View the structure of verd1.scores 
str(verd1.scores, max.level = 1, vec.len = 1)
```

    ## 'data.frame':    22 obs. of  10 variables:
    ##  $ scoreID              : int  1 2 ...
    ##  $ recordingID          : chr  "midEarth3_2016-03-12_07-00-00.wav" ...
    ##  $ templateID           : chr  "verd1" ...
    ##  $ time                 : num  0.499 ...
    ##  $ scoreThreshold       : num  0.2 0.2 ...
    ##  $ score                : num  0.267 ...
    ##  $ manualVerifyLibraryID: int  NA NA ...
    ##  $ manualVerifySpeciesID: int  NA NA ...
    ##  $ features             :List of 22
    ##   ..- attr(*, "class")= chr "blob"
    ##  $ timestamp            : chr  "2019-01-26 16:27:00" ...

As discussed in the **Scores** chapter, each event is given a *scoreID*
associated with a given *recordingID* and *templateID* (‘verd1’), and a
*time*. There are 22 scores associated with the ‘verd1’ template. The
first event occurred at 0.499 seconds into the
‘midEarth3\_2016-03-12\_07-00-00.wav’ recording, with a *score* of
0.267. Notice that the columns *manualVerifyLibraryID* and
*manualVerifySpeciesID* are empty (NA). The **AMMonitor** function
`scoresVerify()` populates these columns with 0s or 1s, where a 1
indicates a target signal and a 0 conveys a false alarm. The *features*
associated with each scoreID are stored as a serialized “blob” within
the database, and play a vital role in this chapter.

With scores in hand, the next step is verification, which may be done at
the signal level (*manualVerifyLibraryID*) or the species level
(*manualVerifySpeciesID*). For example, if we verify at the level of the
**speciesID**, any detected sound produced by the species should be
labeled as a target signal. If we verify at the level of the
**libraryID**, we are strictly seeking signals that match the
**libraryID** associated with the template. For example, if ‘verd1’ is
seeking a two-note Verdin call, we will only label the detection as a
target signal if two notes are contained within the detection window
during verification. Sometimes it can be difficult to decide whether a
detected event should count as a target signal – generally, a research
program should be careful to develop labeling standards consistent with
their research objectives, and that reflect their knowledge of the
target species.

As mentioned, a subset of scores should be verified. Here, for
demonstration, we will verify all of the 22 scoreIDs associated with the
‘verd1’ template contained in the sample database. We verify detected
events using the function `scoresVerify()`. This function is an
**interactive function**, meaning that the user will make entries into
R’s console in response to prompts. Below, we view the arguments:

``` r
# Return the arguments for the scoresVerify function
args(scoresVerify)
```

    ## function (db.path, date.range, recordingID, scoreID, templateID, 
    ##     label.type, directory, token.path = NULL, db.insert = FALSE, 
    ##     overwrite = FALSE, fd.rat = 4, f.lim = c(0, 12), spec.col = gray.3(), 
    ##     box = TRUE, on.col = "#FFA50050", off.col = "#0000FF50", 
    ##     pt.col = "#80008050") 
    ## NULL

As usual, we feed the **db.path** object to the ‘db.path’ argument. In
the ‘recordingID’ argument, we provide a character vector of
recordingIDs in the database for which we would like to verify
detections (alternatively, we can use the ‘date.range’ argument to
specify that we would like to verify all detections produced within a
certain date range). In ‘templateID’, we specify the templateID for
which we would like to verify detections (here, ‘verd1’). We may only
verify detections for one template at a time. Next, the ‘label.type’
argument allows us to specify the level of granularity at which we would
like to verify detections; we may verify scores at the level of the
‘libraryID’ or the ‘speciesID’. The remaining arguments are standard
**AMMonitor** function arguments; ‘directory’ should point to either the
local directory that houses recordings, or a remote Dropbox directory.
If using a Dropbox directory, input the Dropbox token in the
‘token.path’ argument (see **Recordings** chapter for details). As
always, ‘db.insert’ may be set to TRUE to insert verifications directly
to the scores table, or FALSE to simply return a data.table without
modifying the database. When db.insert = TRUE, pay attention to the
argument ‘overwrite’, which allows you to decide whether or not any
previously existing database verifications should be overwritten. If
overwrite = FALSE, users will not be prompted to verify any detected
events that already have a verification. (Finally, there are several
other arguments with default values that allow the user to customize how
detected events should be displayed during the interactive session.
There is also an option to verify specific scoreIDs, in the event that
the user has taken a stratified sample or otherwise selected which
scoreIDs should be verified. We do not review these options here; see
`help('scoresVerify')` for details.)

``` r
# Interactive function; the output cannot be displayed 
verifs <- scoresVerify(db.path = db.path,
                       recordingID = unlist(dbGetQuery(conx, 'SELECT DISTINCT recordingID FROM recordings')),
                       templateID = 'verd1', 
                       label.type = 'libraryID', 
                       directory = getwd(), 
                       token.path = NULL,
                       overwrite = FALSE,
                       db.insert = FALSE)
```

If you run this function, you will be prompted to flag each detected
event as a target signal or false alarm, as demonstrated below. scoreID
1 is in fact a vocalization from the target species, Verdin (‘verd’),
but it is not the two-note Verdin call sought by the libraryID
associated with the template ‘verd1’. Therefore, if verifying at the
level of the libraryID, a user would probably log this as a false alarm
by inputting ‘n’ to the interactive prompt. If verifying at the level of
the speciesID, a user might choose to log this detection as a target
signal by inputting ‘y’ to the interactive prompt.

<img src="Chap17_Figs/scoresVerify.png" width="600" height="400" style="display: block; margin: auto auto auto 0;" />

`scoresVerify()` will return a data.frame that can be used to update
records in the **scores** table. If db.insert = TRUE,
*manualVerifyLibraryID* or *manualVerifySpeciesID* will be automatically
filled in based on your verifications. If a user verifies based on the
*manualVerifyLibraryID* and inputs that the event is a true detection,
*manualVerifySpeciesID* for that record will also be logged as true by
association.

Because `scoresVerify()` is an interactive function, it is diffult to
show the returned data frame in this written vignette. We bypass this
conundrum by directly updating the **scores** table below with
verifications labels we have already generated for you using
`scoresVerify()`. We verified detections based on the **libraryID**, not
the **speciesID**, which means we labeled detected events as target
signals only if two Verdin notes were contained within the detection
window. If only one Verdin note was contained within the detection
window, or if a different type of Verdin call was detected (as in the
scoreID 1 example above), we labeled these as false alarms. Again, the
standards adopted for a given research program may vary based on
monitoring objectives.

Below, we modify this sample chapter’s database to insert our
verifications for the 22 ‘verd1’ detections into the
*manualVerifyLibraryID* column of the sample database **scores** table:

``` r
# Create verifications for the 22 scores for 'verd1'
verifications <- c(0,0,0,0,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1)

# Identify the scoreIDs associated with the 22 'verd1' events
scoreIDs <- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,33,34,35,36,37,38,39)

# Run an update query, passing in the R parameters
RSQLite::dbExecute(conn = conx, 
                   statement =  "UPDATE scores 
                                 SET manualVerifyLibraryID = $vers 
                                 WHERE scoreID = $scoreID", 
                   param = list(vers = verifications, scoreID = scoreIDs))
```

    ## [1] 22

We can view the **scores** table to confirm that verifications have been
added to the *manualVerifyLibraryID* column. Zeroes stand for false
alarms; 1s are target signals.

``` r
RSQLite::dbGetQuery(conn = conx, 
                    statement = 'SELECT scoreID, recordingID, templateID, time,
                                        scoreThreshold, score, manualVerifyLibraryID
                                 FROM scores 
                                 WHERE scoreID = $scoreID',
                    param = list(scoreID = scoreIDs))
```

    ##    scoreID                       recordingID templateID      time scoreThreshold     score manualVerifyLibraryID
    ## 1        1 midEarth3_2016-03-12_07-00-00.wav      verd1  0.499229            0.2 0.2669258                     0
    ## 2        2 midEarth3_2016-03-12_07-00-00.wav      verd1  2.066576            0.2 0.2529111                     0
    ## 3        3 midEarth3_2016-03-12_07-00-00.wav      verd1  3.308844            0.2 0.2538855                     0
    ## 4        4 midEarth3_2016-03-12_07-00-00.wav      verd1  8.695873            0.2 0.2049214                     0
    ## 5        5 midEarth3_2016-03-12_07-00-00.wav      verd1 10.692789            0.2 0.2506303                     0
    ## 6        6 midEarth3_2016-03-12_07-00-00.wav      verd1 13.920363            0.2 0.3788103                     1
    ## 7        7 midEarth3_2016-03-12_07-00-00.wav      verd1 16.997007            0.2 0.2270237                     0
    ## 8        8 midEarth3_2016-03-12_07-00-00.wav      verd1 17.507846            0.2 0.3892711                     1
    ## 9        9 midEarth3_2016-03-12_07-00-00.wav      verd1 20.456780            0.2 0.2547122                     1
    ## 10      10 midEarth3_2016-03-12_07-00-00.wav      verd1 23.754014            0.2 0.3679291                     1
    ## 11      11 midEarth3_2016-03-12_07-00-00.wav      verd1 24.299683            0.2 0.2448099                     0
    ## 12      12 midEarth3_2016-03-12_07-00-00.wav      verd1 28.699864            0.2 0.4061488                     1
    ## 13      13 midEarth3_2016-03-12_07-00-00.wav      verd1 33.053605            0.2 0.2851608                     0
    ## 14      14 midEarth3_2016-03-12_07-00-00.wav      verd1 33.297415            0.2 0.2988873                     1
    ## 15      15 midEarth3_2016-03-12_07-00-00.wav      verd1 37.256417            0.2 0.3101349                     0
    ## 16      33 midEarth5_2016-03-21_07-30-00.wav      verd1  4.678821            0.2 0.8053458                     1
    ## 17      34 midEarth5_2016-03-21_07-30-00.wav      verd1  9.032562            0.2 0.5522207                     1
    ## 18      35 midEarth5_2016-03-21_07-30-00.wav      verd1 25.298141            0.2 0.5519680                     1
    ## 19      36 midEarth5_2016-03-21_07-30-00.wav      verd1 30.220771            0.2 0.4854510                     1
    ## 20      37 midEarth5_2016-03-21_07-30-00.wav      verd1 35.143401            0.2 0.4820545                     1
    ## 21      38 midEarth5_2016-03-21_07-30-00.wav      verd1 39.671293            0.2 0.6246624                     1
    ## 22      39 midEarth5_2016-03-21_07-30-00.wav      verd1 49.400454            0.2 0.3033135                     1

Here, for scoreID = 1, the *manualVerifyLibraryID* column indicates this
event was labeled a false alarm: it is not a two-note Verdin call.

The `plotVerifications()` function plots all verifications we have
generated side by side. We can choose to set the argument ‘plot.scoreID’
to TRUE to plot the scoreIDs on top of the detections. Detections
labeled as target signals are plotted in a single window with green
borders around each detection. Detections labeled as false alarms are
plotted in a single window with red borders around each detection.

``` r
plotVerifications(db.path = db.path, 
                  templateID = 'verd1', 
                  score.threshold = 0.2, 
                  label.type = 'libraryID', 
                  plot.scoreID = TRUE, 
                  new.window = FALSE)
```

<img src="Chap17_Figs/unnamed-chunk-17-1.png" style="display: block; margin: auto auto auto 0;" /><img src="Chap17_Figs/unnamed-chunk-17-2.png" style="display: block; margin: auto auto auto 0;" />

    ## $target.signal.ids
    ##  [1]  6  8  9 10 12 14 33 34 35 36 37 38 39
    ## 
    ## $false.alarm.ids
    ## [1]  1  2  3  4  5  7 11 13 15

Across the 22 detected events for ‘verd1’ template, 13 have been labeled
as target signals, while 9 (including scoreID 1) have been labeled false
alarms. If a verification label appears to be mistaken, we can use
SQLite commands to update the label if we believe it is incorrect
(setting ‘plot.scoreID’ to TRUE allows you to see the scoreIDs of
anything that may have been mislabelled).

The `plotVerificationsAvg()` function generates a four-panel plot that
shows: 1. the template used, 2. a spectrogram showing the mean of all
verified events (where each pixel in the spectrogram reflects the mean
amplitude value at that pixel across all verified events), 3. a
spectrogram of the mean target signal (where each pixel in the
spectrogram reflects the mean amplitude value at that pixel across all
events verified as target signals), and 4. a spectrogram of the mean
false alarm (where each pixel in the spectrogram reflects the mean
amplitude value at that pixel across all events verified as false
alarms).

``` r
plotVerificationsAvg(db.path = db.path, 
                     templateID = 'verd1', 
                     score.threshold = 0.2, 
                     label.type = 'libraryID')
```

<img src="Chap17_Figs/unnamed-chunk-18-1.png" style="display: block; margin: auto auto auto 0;" />

# Training and testing classifiers using classifierModels()

Next, we use verified events to create classification models
(classifiers), finalized versions of which should be stored in an
**AMModels** library for future re-use. Recall that we created several
AMModel libraries in Chapter 1, one of which is dedicted to storing
classifier models (classifiers.RDS). Remember that all AMModel libraries
should be stored in a directory called “ammls”, located within the main
**AMMonitor** directory. We view this model library below using
`readRDS()`. It does not yet contain any models.

``` r
# Read in the model library called classifiers
classifiers <- readRDS('ammls/classifiers.RDS')

# Look at the model library; note it contains 0 models
classifiers
```

    ## 
    ## Description:
    ## [1] This AM Model Library stores classification models.
    ## 
    ## Info:
    ##   personID 
    ##    [1] bbaggins
    ##   date.created 
    ##    [1] 2018-10-10 16:40:19
    ## 
    ## Models:
    ## 
    ##  --- There are no models --- 
    ## 
    ## Data:
    ## 
    ##  --- There are no datasets ---

Soon, we will analyze the verifications, and add classification models
directly to this library.

To create and test a classification model, the verified data must be
split into training and testing datasets. We can split data, train,
test, and assess models using AMMonitor’s `classifierModels()` function.

``` r
# Look at the arguments for the classifierModels function
args(classifierModels)
```

    ## function (db.path, templateID, label.type, score.threshold, scoreID, 
    ##     split.proportion = 0.7, classifiers = c("glmnet", "svmLinear", 
    ##         "svmRadial", "rf", "kknn"), seed, method = "repeatedcv", 
    ##     number = 10, repeats = 5, search = "grid", tuneGrids = NULL) 
    ## NULL

Given a ‘db.path’, a ‘templateID’, and a ‘label.type’,
`classifierModels()` will internally split verified records from the
**scores** table into training and testing datasets according to the
‘split.proportion’ argument. Users should identify which classifiers
to create in the ‘classifiers’ argument. The input to the
‘score.threshold’ argument should match a score.threshold used for
this template in `scoresDetect()` to populate the **scores** table (note
that this argument has nothing to do with classifying an event as a
target signal or false alarm; it merely provides users with a means to
specify which score threshold to use for classifier training, in case
users have generated scores with the same template at multiple template
score thresholds). Users can input a ‘seed’ to encourage reproducible
results if desired. Remaining arguments, which are defaults not
discussed here, are sent to **caret** functions that create the models.

The output of the `classifierModels()` function is a list of models,
where each model itself is a list. Once calibrated, finalized models can
be added to the AMModel library manually by the user.

WARNING: The example function call below may take several minutes to
run, and returns many messages on model progress. Output from the code
below is withheld to save space. We name the returned object
**classifier\_practice** to indicate that we are merely practicing using
`classifierModels()`.

``` r
# Create 5 classifier models 
# do not save to model library until calibrated
classifier_practice <- classifierModels(db.path = db.path, 
                                        templateID = 'verd1', 
                                        label.type = 'libraryID', 
                                        score.threshold = 0.2,
                                        split.proportion = 0.7, 
                                        classifiers =  c('glmnet', 'svmLinear', 'svmRadial', 'rf', 'kknn'), 
                                        seed = 3)
```

``` r
# View structure of the returned models
str(classifier_practice, max.level = 1)
```

    ## List of 5
    ##  $ verd1_0.2_libraryID_glmnet   :List of 9
    ##  $ verd1_0.2_libraryID_svmLinear:List of 9
    ##  $ verd1_0.2_libraryID_svmRadial:List of 9
    ##  $ verd1_0.2_libraryID_rf       :List of 9
    ##  $ verd1_0.2_libraryID_kknn     :List of 9

As shown, the output of `classifierModels()` is a named list containing
lists, where each model is provided a unique name, and the model
elements are stored in a list of nine. Model names for the classifiers
are automatically generated as a string based on the templateID (here,
‘verd1’), score threshold used during template matching (here, 0.2),
label type (here, libraryID), and classifier name.

Below, we take a closer look at one classifier.

``` r
# look at the structure of the first model
str(classifier_practice[['verd1_0.2_libraryID_glmnet']], max.level = 1, vec.len = 1)
```

    ## List of 9
    ##  $ templateID      : chr "verd1"
    ##  $ label.type      : chr "libraryID"
    ##  $ score.threshold : num 0.2
    ##  $ train.scoreID   : int [1:16] 2 4 ...
    ##  $ test.scoreID    : int [1:6] 1 3 ...
    ##  $ training.fit    :List of 20
    ##   ..- attr(*, "class")= chr "train"
    ##  $ test.prediction :'data.frame':    6 obs. of  3 variables:
    ##  $ performance     :'data.frame':    1 obs. of  18 variables:
    ##  $ confusion.matrix: 'table' int [1:2, 1:2] 2 1 ...
    ##   ..- attr(*, "dimnames")=List of 2

Each model list contains nine elements, including basic information such
as the templateID (‘verd1’), label.type (‘libraryID’), and
score.threshold used in `scoresDetect()` (0.2). The ‘train.scoreID’
element records the scoreIDs of verified scores used during the training
phase, while the ‘test.scoreID’ element stores the scoreIDs of verified
scores used during the testing phase. The ‘training.fit’ element is a
large list object generated by **caret** that stores all model training
information (such as the ‘trainingData’, which are the features of each
detected event). See [**caret**
documentation](http://topepo.github.io/caret/index.html) for more
information. The ‘test.prediction’ element stores the predicted class
(target signal, TS; or false alarm, FA) and target signal probabilities
for each testing event. The ‘performance’ element stores this
classifier’s test phase performance on a variety of classifier
assessment metrics, such as accuracy, sensitivity, specificity,
precision, and F1 score. Finally, the ‘confusion.matrix’ element shows a
confusion matrix of all test events used for prediction.

We use the AMMonitor function `classifierPerformance()` to view how each
classifier performed on the test data. This function either takes an
`amModelLib` object in the ‘amml’ argument, or a classifier list object
output from `classifierModels()`, which is our **classifier\_practice**
list object from above. We use the ‘model.names’ argument to specify
which model performance to view.

``` r
# Assess performance of classifier models in the model.list
performance.glmnet <- classifierPerformance(amml = NULL,
                                            model.list = classifier_practice,
                                            model.names = 'verd1_0.2_libraryID_glmnet')

# Look at the structure of performance results for one model
str(performance.glmnet)
```

    ## Classes 'data.table' and 'data.frame':   1 obs. of  19 variables:
    ##  $ Model               : chr "verd1_0.2_libraryID_glmnet"
    ##  $ Accuracy            : num 0.833
    ##  $ Kappa               : num 0.667
    ##  $ AccuracyLower       : num 0.359
    ##  $ AccuracyUpper       : num 0.996
    ##  $ AccuracyNull        : num 0.5
    ##  $ AccuracyPValue      : num 0.109
    ##  $ McnemarPValue       : num 1
    ##  $ Sensitivity         : num 0.667
    ##  $ Specificity         : num 1
    ##  $ Pos Pred Value      : num 1
    ##  $ Neg Pred Value      : num 0.75
    ##  $ Precision           : num 1
    ##  $ Recall              : num 0.667
    ##  $ F1                  : num 0.8
    ##  $ Prevalence          : num 0.5
    ##  $ Detection Rate      : num 0.333
    ##  $ Detection Prevalence: num 0.333
    ##  $ Balanced Accuracy   : num 0.833
    ##  - attr(*, ".internal.selfref")=<externalptr>

Nineteen variables are returned for each model, each providing
information about verd1\_0.2\_libraryID\_glmnet’s ability to distinguish
false alarms from target signals.

We can also look at the performance of all classifiers side by side to
compare their performance, focusing on a few key columns:

``` r
# Assess performance of the glmnet classifier model in an amml or model.list
# Below, we use our classifier_practice model list object and leave amml = NULL
performance.all <- classifierPerformance(amml = NULL,
                                         model.list = classifier_practice,
                                         model.names = names(classifier_practice)) 

# Look at the structure of performance results for each model
performance.all[,c('Model', 'Accuracy', 'Sensitivity', 'Specificity', 'Precision', 'F1')]
```

    ##                            Model Accuracy Sensitivity Specificity Precision     F1
    ## 1:    verd1_0.2_libraryID_glmnet   0.8333      0.6667      1.0000    1.0000 0.8000
    ## 2: verd1_0.2_libraryID_svmLinear   0.8333      0.6667      1.0000    1.0000 0.8000
    ## 3: verd1_0.2_libraryID_svmRadial   0.5000      1.0000      0.0000    0.5000 0.6667
    ## 4:        verd1_0.2_libraryID_rf   0.6667      0.6667      0.6667    0.6667 0.6667
    ## 5:      verd1_0.2_libraryID_kknn   0.8333      0.6667      1.0000    1.0000 0.8000

There are five key metrics often used to evaluate classifier
performance. The most intuitive of these is “accuracy”, which represents
the overall number of prediction cases correctly identified as target
signals and false alarms by the classifier. The regularized logistic
regression (‘glmnet’), linear support vector machine (‘svmLinear’), and
kernelized k-nearest neighbor (‘kknn’) classifiers tie for best
performance on the accuracy metric, with 83% accuracy (0.833).
Meanwhile, the radial support vector machine (svmRadial) performs worst
(0.5, 50% accuracy).

However, accuracy is often a poor metric to rely upon when there is a
class imbalance in the prediction data. In an example with 100 new
prediction cases, if 95 events are false alarms, and 5 are target
signals, a classifier that predicts *everything* to be a false alarm
will be 95% accurate. If our real goal is to successfully find the five
target signals, this classifier is useless to us despite its high
accuracy. This phenomenon is known as the [Accuracy
Paradox](https://en.wikipedia.org/wiki/Accuracy_paradox).

Instead, we may strive to maximize a metric called
“[sensitivity](https://en.wikipedia.org/wiki/Sensitivity_and_specificity)”
(also known as “recall” or “true positive rate”), which calculates the
proportion of target signals correctly identified by the classifier. The
**performance.all** object shows that svmRadial scores a 1 on
sensitivity, which means it correctly identified 100% of target signals
as target signals (and did not mistakenly classify any of these cases as
false alarms). Meanwhile, glmnet, svmLinear, rf, and kknn all scored
0.667 on sensitivity, which means they were only able to correctly
identify 67% of the target signals as such.

Conversely, we are often also interested in a classifier’s
“[specificity](https://en.wikipedia.org/wiki/Sensitivity_and_specificity)”
(also known as “true negative rate”), which speaks to its ability to
correctly identify false alarms and label them as such. In
**performance.all**, we note the range of performances on the
specificity metric: glmnet, svmLinear, and kknn each score 1 on
specificity – they performed perfectly at identifying false alarms. The
rf classifier only scored 0.667 on this metric, indicating that it was
not as adept at identifying false alarms. The svmRadial classifier,
which was great at identifying target signals, fails entirely at
identifying false alarms: it scored 0.

The interplay between specificity and sensitivity is captured by the
metric
“[precision](https://en.wikipedia.org/wiki/Positive_and_negative_predictive_values)”
(also known as “positive predictive value”), which reflects the
proportion of predicted target signals that are *actually* target
signals. In **performance.all**, note that glmnet, svmLinear, and kknn
each have perfect precision (100%): this means all of the events they
predicted to be target signals ARE target signals. Meanwhile, svmRadial
has a poor precision score of 0.5. This is because it mistakenly
confused several false alarms with target signals, so although its
sensitivity is perfect (1), its inability to identify false alarms
(specificity = 0) causes poor precision.

Finally, the “[F1 score](https://en.wikipedia.org/wiki/F1_score)”
represents a weighted average of precision and sensitivity, quantifying
the tradeoff between a desire for high sensitivity and high precision.
In **performance.all**, F1 scores range from 0.667 (rf, svmRadial) to
0.8 (glmnet, svmLinear, kknn).

For additional evaluation, we may also construct [Receiver-Operating
Characteristic (ROC)
curves](https://en.wikipedia.org/wiki/Receiver_operating_characteristic)
on the test data, which plot the true positive rate (sensitivity)
against the false positive rate (1 – specificity). In addition to the
‘db.path’, `plotRoc()` takes either an ‘amml’ or a ‘model.list’ object
output from `classifierModels()`, as well as ‘model.names’. In the
‘curve.type’ argument, we specify ‘roc’. In the ‘data.type’ argument,
we specify whether we would like to create ROC curves of the training or
testing data (we have input ‘test’, but we could have chosen to plot the
training data by inputting ‘train’). Below, our ROC curves will look
rather blocky due to the low sample size of test data in the example.
The glmnet, svmLinear, and rf classifiers each plot the same line, with
area under the ROC curve (AUC) values of 0.89 (higher values are more
desirable). The kknn AUC value is slightly lower (0.83), while svmRadial
has an AUC value of 0 – worse than a random guess.

``` r
plotROC(db.path = db.path, 
        amml = NULL,
        model.list = classifier_practice, 
        model.names = names(classifier_practice), 
        curve.type = 'roc',
        data.type = 'test')
```

<img src="Chap17_Figs/unnamed-chunk-27-1.png" style="display: block; margin: auto auto auto 0;" />

As mentioned above, many classification problems involve imbalanced
datasets, in which the number of false alarm cases greatly outweighs the
number of target signal cases or vice versa. Class imbalances undermine
performance metrics like accuracy and area under the ROC curve (AUC): a
classifier may predict the majority class for most or all observations
in the test set and still attain a high accuracy score, which is why
measures beyond accuracy are necessary \[3\].

Thus, **AMMonitor** also offers the chance to construct Precision-Recall
Curves, which plot precision (a.k.a. positive predictive value) against
sensitivity (a.k.a. recall) \[4\]. Like ROC curves, AUC values closest
to 1 are best. This time, we set ‘curve.type’ equal to ‘pr’ to generate
a Precision-Recall plot. Here, we want to see curve values tightly drawn
into the upper right-hand corner. The knn classifier comes closest, with
an AUC of 0.92. The glmnet, svmLinear, and rf classifiers each plot the
same line over one another and have matching AUC values of 0.9. The
svmRadial classifier again performs poorly (0.25).

``` r
plotROC(db.path = db.path, 
        amml = NULL,
        model.list = classifier_practice, 
        model.names = names(classifier_practice), 
        curve.type = 'pr',
        data.type = 'test')
```

<img src="Chap17_Figs/unnamed-chunk-28-1.png" style="display: block; margin: auto auto auto 0;" />

In Precision-Recall curves, the dotted line, which signifies the
performance of a random guess classifier, is always horizontal and
extends from the Y-axis value representing the overall prevalence of
target signals in the test data set. We can check how many cases were
used for testing by looking at the model.list:

``` r
# Get the labels for training or testing data
scoreIDs <- classifier_practice[[1]]$test.scoreID

# Acquire scores for the desired label.type based on input templateID and score.threshold
look.at.test.data <- data.table(
  RSQLite::dbGetQuery(conn = conx,
             statement = "SELECT scoreID, manualVerifyLibraryID
                          FROM scores 
                          WHERE scoreID = $scoreID",
             params = list(scoreID = scoreIDs)))

# Look at the data used for testing 
look.at.test.data
```

    ##    scoreID manualVerifyLibraryID
    ## 1:       1                     0
    ## 2:       3                     0
    ## 3:      15                     0
    ## 4:      33                     1
    ## 5:      37                     1
    ## 6:      39                     1

We note that we only had six cases used for testing; three of these were
target signals, and three were false alarms. Thus, the prevalence of
target signals in this population is 3/6, or 0.5, which is why the
dotted horizontal line starts at 0.5 on the y-axis of the
Precision-Recall curve. Note that an even class split like this is often
not the case, which is why Precision-Recall curves are useful.

A user might calibrate a model by experimenting with the
‘split.proportion’ argument until satisfied with classifier
performance metric outcomes. A user may also return to `scoresVerify()`
to label additional scores, increasing the amount of training data
available to the classifier models.

Calibrated models can be added directly to an AMModel library, where
they can be called for future use. Here, we return to our empty library
called ‘classifiers’, which is an RDS file stored in the ‘ammls’
directory.

If we are satisfied with our trained models, we may add them to the
‘classifiers’ AMModel library as named **amModel** objects, ensuring
that each classifier retains its auto-generated name
(e.g. ‘verd1\_0.2\_libraryID\_glmnet’).

``` r
# Turn each classifier model into an ammodel object:
mods <- list()
for (i in seq_along(classifier_practice)) {
  mods[[i]] <- AMModels::amModel(model = classifier_practice[[i]], comment = '')
}

# Name the list:
names(mods) <- names(classifier_practice)

# Insert into amml:
classifiers <- AMModels::insertAMModelLib(models = mods, 
                                          amml = classifiers)
# Save to amml folder:
saveRDS(classifiers, 'ammls/classifiers.RDS')
```

Now stored in the ‘classifiers’ model library, these models can be
accessed again at any time and used to make predictions on **new** data.
Note that in practice, we would likely not want to store a classifier
that performed as poorly as the svmRadial classifier did here.

# Making predictions on new data using classifierPredict()

Once classification models have been trained and tuned, we can use them
to make predictions on new incoming data with `classifierPredict()`.
This function’s main arguments are the ‘db.path’, a ‘date.range’ over
which to make predictions, and the ‘templateID’, ‘label.type’, and
‘score.threshold’ at which to make predictions. In the ‘classifiers’
argument, we specify which classifiers should be used to make
predictions.

This function returns a data.table of classifications, which can be
automatically added to the database’s **classifications** table if
‘db.insert’ is set to TRUE. If so, `classifierPredict()` will check
the **classifications** table for predictions that were made according
to each combination of scoreID, templateID, label.type, score.threshold,
and classifiers, and will only add predictions for new combinations.

``` r
new.classifs <- classifierPredict(db.path = db.path,
                                  date.range = c('2016-03-01', '2016-03-30'),
                                  templateID = 'verd1', 
                                  label.type = 'libraryID', 
                                  score.threshold = 0.2, 
                                  classifiers =  c('glmnet', 'svmRadial', 
                                                   'svmLinear', 'rf'),
                                  amml = classifiers,
                                  db.insert = FALSE)
```

The **new.classifs** object shows what would be input to the
**classifications** table should ‘db.insert’ be set to TRUE.

Below, we view classifications associated with scoreID == 1:

``` r
# Return classifications associated with scoreID 1
new.classifs[which(new.classifs$scoreID == 1),]
```

    ##    scoreID        amml classifier                     modelName modelProbability           timestamp
    ## 1:       1 classifiers     glmnet    verd1_0.2_libraryID_glmnet       0.17018835 2019-07-24 14:15:34
    ## 2:       1 classifiers  svmRadial verd1_0.2_libraryID_svmRadial       0.61615217 2019-07-24 14:15:34
    ## 3:       1 classifiers  svmLinear verd1_0.2_libraryID_svmLinear       0.08530979 2019-07-24 14:15:35
    ## 4:       1 classifiers         rf        verd1_0.2_libraryID_rf       0.33000000 2019-07-24 14:15:35

Note that these data are identical to those we examined at the start of
this chapter. We store the *scoreID* and the *amml* name associated with
this model. We also store the *classifier* and *modelName* associated
with this prediction. Next, *modelProbability* signifies the probability
that a detected event is a target signal. Finally, we track the
*timestamp* at which the prediction was entered into the database.

# Creating Ensemble Predictions

In Chapter 18: Analyses, we illustrate how to combine predictions from
the five classifiers into a basic “ensemble” classifier that aggregates
the predictions of multiple classifiers.

Before doing so, we can investigate the performance of combined
predictions from multiple classifiers by using the
`classifierEnsemble()` function. `classifierEnsemble()` takes the
predictions from several classifiers and generates a data.table of
‘ensemble’ classifications averaged across multiple classifiers. This
‘ensemble’ is a weighted average that may be computed according to
each classifier’s performance on accuracy, sensitivity, specificity,
precision, F1 score, or a simple average across all classifiers.

To illustrate the concept of a precision-weighted ‘ensemble’, we will
use `classifierPerformance()` to remind ourselves how all five
classifiers performed on the test data. Pulling out a few columns, we
recall that the glmnet, svmLinear, and kknn classifiers performed best
on the precision metric, each scoring a 1. If we use a
precision-weighted average ensemble in `classifierEnsemble()`, this
means the glmnet, svmLinear, and kknn classifiers have the highest
“weight” in the weighted average. Meanwhile, svmRadial performs worst
on precision, with a score of 0.5; it will have the lowest weight in the
precision-weighted average.

``` r
# Assess model performance during the training and testing phase: 
performance <- classifierPerformance(model.list = classifier_practice, 
                                     model.names = names(classifier_practice))

# Compare model performance for 5 metrics
performance[, c('Model', 'Accuracy', 'Sensitivity', 'Specificity', 'Precision', 'F1')]
```

    ##                            Model Accuracy Sensitivity Specificity Precision     F1
    ## 1:    verd1_0.2_libraryID_glmnet   0.8333      0.6667      1.0000    1.0000 0.8000
    ## 2: verd1_0.2_libraryID_svmLinear   0.8333      0.6667      1.0000    1.0000 0.8000
    ## 3: verd1_0.2_libraryID_svmRadial   0.5000      1.0000      0.0000    0.5000 0.6667
    ## 4:        verd1_0.2_libraryID_rf   0.6667      0.6667      0.6667    0.6667 0.6667
    ## 5:      verd1_0.2_libraryID_kknn   0.8333      0.6667      1.0000    1.0000 0.8000

In `classifierEnsemble()`, the weighted average ‘ensemble’ options are
c(‘accuracy’, ‘sensitivity’, ‘specificity’, ‘precision’, ‘f1’,
‘simple’); instead of precision, we could alternatively choose to
construct our weighted average ensemble models based on the accuracy,
sensitivity, specificity, or F1 scores. One final option is that we
could merely choose to take an unweighted average of each classifier’s
target signal probability prediction for a given observation (‘simple’).
If there are any sub-optimal performances in the set of classifier
models, like svmLinear, we can choose to leave them out of the ensemble
entirely by omitting them from the ‘models’ element of the model.list
object (or by not storing them in a classifiers.RDS amml to begin with).

In addition to the ‘db.path’, `classifierEnsemble()` requires either an
‘amml’ or ‘model.list’ object for input, and includes a variety of
options for argument inputs as detailed in the helpfile. Below, we use
the ‘model.names’ argument to specify which models should be included in
the ensemble, and the ‘ensemble’ argument to specify that we would like
to create the ensemble based on precision-weighted averages. Because we
are inputting our **classifier\_practice** object into the ‘model.list’
argument, `classifierEnsemble()` will return predictions only on the
test data in the model.list (please read the helpfile to understand how
this function’s behavior changes based on the arguments a user chooses).

``` r
# Create ensemble classifier predictions on the test data by inputting a model.list object
ens <- classifierEnsemble(db.path = db.path, 
                          amml = NULL,
                          model.list = classifier_practice, 
                          model.names = names(classifier_practice), 
                          ensemble = 'precision')

# View the first few records
ens
```

Note that `ensembleClassifier()` returns a data.table with five columns.
These are the *scoreID*, *classifier* (which conveys the ensemble type
selected by the user), *modelProbability* (the weighted average
probability of target signal returned by all classifiers input to the
‘model.names’ argument), *class* (the true class for this signal, if
contained in the database, as 1: target signal, or 0: false alarm), and
*predicted* (the predicted class for this signal based on the ensemble
model probability). The *class* and *predicted* columns provide easy
inputs to the **caret** package’s `confusionMatrix()` function for
assessing performance of the ensemble classifier.

``` r
caret::confusionMatrix(data = ens$predicted, reference = ens$class)
```

    ## Confusion Matrix and Statistics
    ## 
    ##           Reference
    ## Prediction 1 0
    ##          1 2 0
    ##          0 1 3
    ##                                           
    ##                Accuracy : 0.8333          
    ##                  95% CI : (0.3588, 0.9958)
    ##     No Information Rate : 0.5             
    ##     P-Value [Acc > NIR] : 0.1094          
    ##                                           
    ##                   Kappa : 0.6667          
    ##                                           
    ##  Mcnemar's Test P-Value : 1.0000          
    ##                                           
    ##             Sensitivity : 0.6667          
    ##             Specificity : 1.0000          
    ##          Pos Pred Value : 1.0000          
    ##          Neg Pred Value : 0.7500          
    ##              Prevalence : 0.5000          
    ##          Detection Rate : 0.3333          
    ##    Detection Prevalence : 0.3333          
    ##       Balanced Accuracy : 0.8333          
    ##                                           
    ##        'Positive' Class : 1               
    ## 

Note that `classifierEnsemble()` does not have options for adding
ensemble results to the classifications database. It merely provides a
way to view ensemble predictions, which can then be assessed with the
**caret** `confusionMatrix()` function. Looking forward, functions in
Chapter 18 (Analyses) can optionally run `classifierEnsemble()` to
generate encounter histories from an ensemble rather than from a single
classifier.

# The Classifications Table in Access

The classifications table is located under the “Scores” secondary tab,
within the “Recordings” primary tab in the Access Navigation Form.

<kbd>

<img src="Chap17_Figs/scores.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 17.1. The classifications table stores the probability that a
> detected event is a true positive detection. These data can be used in
> a large variety of ways to address ecological hypotheses.*

Here, we view the first record of the **scores** table, and note that
there are 52 records in this table. This record was registered by
pitting templateID “verd1” against the recordingID
“midEarth3\_2016-03-12\_07-00-00.wav”. This score has a value of
0.2669, and is logged in the scores table because it exceeded the
user-supplied threshold of 0.2, which was input by the user to
`scoresDetect()`. Five different models have been created to assess the
“verd1” template, with model names that were automatically generated
and that provide the templateID, score threshold, classifier type, and
whether scores were verified at the libraryID level or the speciesID
level. Each of the five **AMMonitor** classifiers evaluated scoreID 1,
and produced a probability that the signal was a target signal (1 minus
this value provides the probability that the signal is a false alarm).

Note that the **scores** and **classifications** tables are filled in by
**AMMonitor** functions, and are not intended to be entered manually.

# Chapter Summary

This chapter covered the **classifications** table, which stores the
probability that a template-detected event is a target signal. To fill
this table, users can verify a subset of scores with `scoresVerify()`,
and check their verifications using `plotVerifications()` and
`plotVerificationsAvg()`. Verifications can be used to train and test a
suite of five classifier models using `classifierModels()`. Model
performance can be assessed with `classifierPerformance()` and
`plotROC()`. Sufficient models may be stored in the
‘ammls/classifiers.RDS’ AMModels library and called into action to
make predictions on incoming detections via `classifierPredict()`. This
function populates the **classifications** table with records if
specified. In short, the **classifications** approach takes a single
event, and uses one or more machine learning approaches to return the
probability that it is a target signal. This approach has many benefits,
as described in the next chapter.

# Chapter References

<div id="refs" class="references">

<div id="ref-BalanticStatistical">

1\. Balantic CM, Donovan TM. Statistical learning mitigation of false
positives from template-detected data in automated acoustic wildlife
monitoring. Bioacoustics. 2019;0: 1–26.
doi:[10.1080/09524622.2019.1605309](https://doi.org/10.1080/09524622.2019.1605309)

</div>

<div id="ref-caret">

2\. Kuhn M. Caret: Classification and regression training (version 6.0)
\[Internet\]. Comprehensive R Archive Network; 2018. Available:
<https://cran.r-project.org/web/packages/caret/index.html>

</div>

<div id="ref-Zhu2007">

3\. Zhu X., Davidson I. Knowledge discovery and data mining. 2007; 

</div>

<div id="ref-Davis2006">

4\. Davis J., Goadrich M. The relationship between precision-recall and
roc curves. Proceedings of the 23rd international conference on Machine
Learning. 2006; 233–240. 

</div>

</div>
