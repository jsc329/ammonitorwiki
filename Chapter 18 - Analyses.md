The previous chapter, Classifications, explained how each detected event
from an acoustic recording or photograph is assigned a probability that
it is the target signal you seek. This table provides the raw material
for a wide range of ecological analyses. For example, you may be
interested in:

-   analyzing the rate at which certain signals are issued by a target
    species through both time and space;
-   determining the community composition, such as species richness or
    diversity, across target species;
-   exploring species interactions;
-   mapping distribution patterns;
-   assessing a population trend through time across locations.

In other words, there are many, many ways to analyze data stored in the
classifications tabl. In this chapter, we illustrate how data stored in
the **classifications** table can be analyzed to assess species trends
through time.

Dynamic Occupancy Models
========================

One way to monitor changes in species distribution patterns over time is
to use a dynamic occupancy model, also known as a multi-season occupancy
model. Occupancy models were largely developed by researchers at the
Patuxent Wildlife Research Center, and now play a central role in
monitoring species worldwide. The data input to the original dynamic
occupancy model \[1\] are a log of the presence or absence of a target
species across both space and time. The main outputs are a current
estimate of occupancy rate, along with information about factors that
influence **changes** in occupancy through time. To illustrate an input,
suppose a single study site was searched for a target species three
times each summer for four years. The “encounter history” for this site
might look like the following:

101 000 100 000

This history has four primary periods (years, in this case), and three
secondary periods per primary period (three surveys per year). More
specifically, in year 1, the species was detected on the first survey,
not detected on the second survey, and detected on the third survey. In
the summer of year 2, the species was not detected during any of the
three surveys. In year 3, the species was detected on the first survey,
but not in surveys 2 or 3. Finally, in year 4, the species was not
detected during any of the three surveys. There are a few critical
assumptions of the original dynamic occupancy model:

1.  **Within a primary period**, at least two repeat surveys are
    required (here, we had three repeat surveys), and we assume that the
    occupancy state of the site is unchanged. If the species was present
    in the first survey, we assume it was also present during the second
    and third surveys within the same season.

2.  **Between primary periods**, occupancy state may change. This means
    if a site was occupied in any given primary period, it may go
    *locally extinct* in the next primary period. If a site was
    unoccupied in any given primary period, it may become *colonized* in
    the next primary period.

3.  Detection is imperfect. We observe an example of imperfect detection
    in the first primary period, where the history is 101. If the site
    is closed to changes in occupancy state during this period, and if
    we assume that the first detection is not an error, we assume the
    species occupied the site during the second survey but was not
    detected. Failure to detect a present species is an example of a
    false-negative detection at the survey level.

4.  Though false negative detections are possible in the standard
    occupancy model, most frameworks assume false positives are not
    possible. Thus, if a detection does occur, we accept that the
    species is present.

With dynamic models, a large number of sites are typically surveyed
through time. In addition to the encounter histories themselves,
researchers may collect a number of site-level covariates (such as the
patch size associated with each monitoring location), and survey-level
covariates (such as prevailing weather conditions during a given
survey). The encounter histories, along with site- and survey-level
covariates, are inputs to the dynamic occupancy model. For outputs, the
model returns estimates of the following parameters (along with
estimates of the influence of covariates on these parameters):

-   psi (*ψ*): the probability a site is occupied.
-   p: the probability a species will be detected during a survey, given
    presence.
-   epsilon (*ϵ*): the probability an occupied site will go locally
    extinct in the next primary period.
-   gamma (*γ*): the probability an unoccupied site will be locally
    colonized in the next primary period.

Thus, the dynamic occupancy framework is an ideal framework for testing
metapopulation theory. Now that’s cool! :sunglasses:

In 2013, David Miller and colleagues contributed an important paper
entitled [Determining Occurrence Dynamics when False Positives Occur:
Estimating the Range Dynamics of Wolves from Public Survey
Data](https://journals.plos.org/plosone/article?id=10.1371/journal.pone.0065808)
\[2\]. In this paper, the authors extended the dynamic model to include
the possibility that some detections may be false positives, wherein a
species is detected even though it is not present (hereafter, the
“Miller model”). For example, the third primary period in the above
encounter history was recorded as 100. The species was recorded as
present, but if we relax the standard occupancy assumption that no false
positives are possible, we now consider that this detection occurred in
error. To accommodate the possibility of false positives, the Miller
model requires a subset of detections to be verified by a second
methodology in which false positives are not possible. If the
alternative methodology confirms that the target species is indeed
present, the survey is logged with a ‘2’ instead of a ‘1’. For example,
the encounter history above,

101 000 100 000

can be changed to

102 000 100 000.

In this example, we confirmed the presence of the target species in the
third survey within the first period by a different survey method, which
is indicated by the number 2. Such confirmation can improve model
performance, leading to improved parameter estimates, and ultimately,
better-informed resource management \[3\].

In addition to the four parameters listed above (psi, p, epsilon,
gamma), the Miller model uses maximum likelihood methods to estimate:

-   p\_{10}: the probability of a false positive detection at an
    unoccupied site.
-   b: the probability the detection will be certain, conditional on
    detecting the species at an occupied site.

Our goal for this chapter is to illustrate a Miller model analysis
within the **AMMonitor** framework. In **AMMonitor**, we use detections
in the **scores** table or **classifications** table to create the
binary portion of the encounter history (0s and 1s), while annotations
and verifications, stored in the **annotations** and **scores** tables,
respectively, are used to “confirm” surveys (signified by 2s in the
encounter history). From these data, we create Miller-type occupancy
encounter histories for each site, and then send the data to the
program, PRESENCE \[4\], for analysis. The outputs of this model provide
not only site-occupancy estimates, but also may identify covariates that
can be managed to influence the system toward a desired occupancy level
(a topic we will visit in the next chapter). We tested the bias and
precision of the Miller model in automated acoustic monitoring, and
found that the model performed well under a variety of conditions \[3\].

Our target species for this chapter is the Verdin (*Auriparus
flaviceps*), a small songbird found in the southwestern United States.

RPresence
=========

The Miller model can be run in R via the package RPresence \[5\]. To use
RPresence, you will need to download both PRESENCE and RPresence from
<a href="https://www.mbr-pwrc.usgs.gov/software/presence.html" class="uri">https://www.mbr-pwrc.usgs.gov/software/presence.html</a>.
PRESENCE software can be installed to your machine; the RPresence
package comes as a zipped folder, and you will need to unzip it and add
it to your site library. Recall that base R packages (the ones that come
when you download R) are typically maintained in your Programs directory
of your computer, while “add-on” packages (such as RPresence) are
typically stored in your “site library”. To find your own library
locations, use the `.libPaths()` function.

    > .libPaths()

    [1] "C:/RSiteLibrary"                    "C:/Program Files/R/R-3.6.0/library"

Here, our main R installation is stored in the Program Files directory
on our C drive, while “add-on” packages are stored in a directory called
“RSiteLibrary”, also on our C drive. Regardless of where your “site
library” is located, you should download RPresence and copy it to your
site library.

To illustrate the process of creating dynamic occupancy models from
automated detection data, we will use the `dbCreateSample()` function to
create a database called “Chap18.sqlite”, which will be stored in a
folder (directory) called “database” within the **AMMonitor** main
directory, which should be your working directory in R. Recall that
`dbCreateSample()` generates all tables of an **AMMonitor** database,
and then pre-populates sample data into tables specified by the user.

Here, we create a sample data base with pre-populated data for several
necessary tables using the `dbCreateSample()` function below.

    > # Create a sample database for this chapter
    > dbCreateSample(db.name = "Chap18.sqlite", 
    +                file.path = paste0(getwd(),"/database"), 
    +                tables = c('templates', 'recordings',
    +                           'equipment', 'locations',
    +                           'accounts', 'library',
    +                           'species', 'people', 
    +                           'lists', 'listItems',
    +                           'scores','classifications', 
    +                            'annotations', 'objectives',
    +                           'temporals', 'spatials'))

    An AMMonitor database has been created with the name Chap18.sqlite which consists of the following tables: 

    accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals


    Sample data have been generated for the following tables: 
    accounts, lists, people, species, spatials, equipment, locations, library, listItems, objectives, recordings, annotations, templates, scores, classifications, temporals

Now, we connect to the database. First, we initialize a character
object, **db.path**, that holds the database’s full file path. Then, we
create a database connection object, **conx**, using RSQLite’s
`dbConnect()` function, where we identify the SQLite driver in the ‘drv’
argument, and our **db.path** object in the ‘dbname’ argument:

    > # Establish the database file path as db.path
    > db.path <- paste0(getwd(), '/database/Chap18.sqlite')
    > 
    > # Connect to the database
    > conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)

After that, we send a SQL statement that will enforce foreign key
constraints.

    > # Turn the SQLite foreign constraints on
    > dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;" )

    <SQLiteResult>
      SQL  PRAGMA foreign_keys = ON;
      ROWS Fetched: 0 [complete]
           Changed: 0

Next, we view the **scores** table that comes with our sample database,
which contains scores associated produced by templates ‘verd1’, ‘verd2’,
and ‘verd3’, all of which were created to find Verdin vocalizations:

    > # Retrieve the sample scores
    > scores <- dbGetQuery(conn = conx, statement = "SELECT * FROM scores")
    > 
    > # Return the scores
    > scores

       scoreID                       recordingID templateID      time scoreThreshold      score manualVerifyLibraryID manualVerifySpeciesID
    1        1 midEarth3_2016-03-12_07-00-00.wav      verd1  0.499229            0.2  0.2669258                    NA                    NA
    2        2 midEarth3_2016-03-12_07-00-00.wav      verd1  2.066576            0.2  0.2529111                    NA                    NA
    3        3 midEarth3_2016-03-12_07-00-00.wav      verd1  3.308844            0.2  0.2538855                    NA                    NA
    4        4 midEarth3_2016-03-12_07-00-00.wav      verd1  8.695873            0.2  0.2049214                    NA                    NA
    5        5 midEarth3_2016-03-12_07-00-00.wav      verd1 10.692789            0.2  0.2506303                    NA                    NA
    6        6 midEarth3_2016-03-12_07-00-00.wav      verd1 13.920363            0.2  0.3788103                    NA                    NA
    7        7 midEarth3_2016-03-12_07-00-00.wav      verd1 16.997007            0.2  0.2270237                    NA                    NA
    8        8 midEarth3_2016-03-12_07-00-00.wav      verd1 17.507846            0.2  0.3892711                    NA                    NA
    9        9 midEarth3_2016-03-12_07-00-00.wav      verd1 20.456780            0.2  0.2547122                    NA                    NA
    10      10 midEarth3_2016-03-12_07-00-00.wav      verd1 23.754014            0.2  0.3679291                    NA                    NA
    11      11 midEarth3_2016-03-12_07-00-00.wav      verd1 24.299683            0.2  0.2448099                    NA                    NA
    12      12 midEarth3_2016-03-12_07-00-00.wav      verd1 28.699864            0.2  0.4061488                    NA                    NA
    13      13 midEarth3_2016-03-12_07-00-00.wav      verd1 33.053605            0.2  0.2851608                    NA                    NA
    14      14 midEarth3_2016-03-12_07-00-00.wav      verd1 33.297415            0.2  0.2988873                    NA                    NA
    15      15 midEarth3_2016-03-12_07-00-00.wav      verd1 37.256417            0.2  0.3101349                    NA                    NA
    16      16 midEarth3_2016-03-12_07-00-00.wav      verd2  0.522449            0.2  0.2324151                    NA                    NA
    17      17 midEarth3_2016-03-12_07-00-00.wav      verd2  2.066576            0.2  0.2511249                    NA                    NA
    18      18 midEarth3_2016-03-12_07-00-00.wav      verd2  3.332063            0.2  0.2185431                    NA                    NA
    19      19 midEarth3_2016-03-12_07-00-00.wav      verd2  8.719093            0.2  0.2051415                    NA                    NA
    20      20 midEarth3_2016-03-12_07-00-00.wav      verd2 10.727619            0.2  0.2211102                    NA                    NA
    21      21 midEarth3_2016-03-12_07-00-00.wav      verd2 13.943583            0.2  0.2266084                    NA                    NA
    22      22 midEarth3_2016-03-12_07-00-00.wav      verd2 16.997007            0.2  0.2737623                    NA                    NA
    23      23 midEarth3_2016-03-12_07-00-00.wav      verd2 17.519456            0.2  0.2976211                    NA                    NA
    24      24 midEarth3_2016-03-12_07-00-00.wav      verd2 20.247800            0.2  0.2271106                    NA                    NA
    25      25 midEarth3_2016-03-12_07-00-00.wav      verd2 23.754014            0.2  0.2272191                    NA                    NA
    26      26 midEarth3_2016-03-12_07-00-00.wav      verd2 24.044263            0.2  0.2040542                    NA                    NA
    27      27 midEarth3_2016-03-12_07-00-00.wav      verd2 24.299683            0.2  0.2103535                    NA                    NA
    28      28 midEarth3_2016-03-12_07-00-00.wav      verd2 28.189025            0.2  0.2167333                    NA                    NA
    29      29 midEarth3_2016-03-12_07-00-00.wav      verd2 28.699864            0.2  0.3197995                    NA                    NA
    30      30 midEarth3_2016-03-12_07-00-00.wav      verd2 33.065215            0.2  0.2349998                    NA                    NA
    31      31 midEarth3_2016-03-12_07-00-00.wav      verd2 34.353923            0.2  0.2097564                    NA                    NA
    32      32 midEarth3_2016-03-12_07-00-00.wav      verd2 37.256417            0.2  0.3569648                    NA                    NA
    33      33 midEarth5_2016-03-21_07-30-00.wav      verd1  4.678821            0.2  0.8053458                    NA                    NA
    34      34 midEarth5_2016-03-21_07-30-00.wav      verd1  9.032562            0.2  0.5522207                    NA                    NA
    35      35 midEarth5_2016-03-21_07-30-00.wav      verd1 25.298141            0.2  0.5519680                    NA                    NA
    36      36 midEarth5_2016-03-21_07-30-00.wav      verd1 30.220771            0.2  0.4854510                    NA                    NA
    37      37 midEarth5_2016-03-21_07-30-00.wav      verd1 35.143401            0.2  0.4820545                    NA                    NA
    38      38 midEarth5_2016-03-21_07-30-00.wav      verd1 39.671293            0.2  0.6246624                    NA                    NA
    39      39 midEarth5_2016-03-21_07-30-00.wav      verd1 49.400454            0.2  0.3033135                    NA                    NA
    40      40 midEarth5_2016-03-21_07-30-00.wav      verd2  4.678821            0.2  0.5208158                    NA                    NA
    41      41 midEarth5_2016-03-21_07-30-00.wav      verd2  9.044172            0.2  0.9861451                    NA                    NA
    42      42 midEarth5_2016-03-21_07-30-00.wav      verd2 25.309751            0.2  0.5015457                    NA                    NA
    43      43 midEarth5_2016-03-21_07-30-00.wav      verd2 30.232381            0.2  0.4601560                    NA                    NA
    44      44 midEarth5_2016-03-21_07-30-00.wav      verd2 35.143401            0.2  0.5188807                    NA                    NA
    45      45 midEarth5_2016-03-21_07-30-00.wav      verd2 39.682902            0.2  0.5024478                    NA                    NA
    46      46 midEarth5_2016-03-21_07-30-00.wav      verd2 49.412063            0.2  0.2669704                    NA                    NA
    47      47 midEarth5_2016-03-21_07-30-00.wav      verd3  4.690431           13.0 17.4513917                    NA                    NA
    48      48 midEarth5_2016-03-21_07-30-00.wav      verd3  9.044172           13.0 27.3304927                    NA                    NA
    49      49 midEarth5_2016-03-21_07-30-00.wav      verd3 25.309751           13.0 14.3483504                    NA                    NA
    50      50 midEarth5_2016-03-21_07-30-00.wav      verd3 30.220771           13.0 13.7519059                    NA                    NA
    51      51 midEarth5_2016-03-21_07-30-00.wav      verd3 35.155011           13.0 15.9197512                    NA                    NA
    52      52 midEarth5_2016-03-21_07-30-00.wav      verd3 39.682902           13.0 15.6923562                    NA                    NA
             features           timestamp
    1  blob[37.22 kB] 2019-01-26 16:27:00
    2  blob[37.22 kB] 2019-01-26 16:27:00
    3  blob[37.22 kB] 2019-01-26 16:27:00
    4  blob[37.22 kB] 2019-01-26 16:27:00
    5  blob[37.22 kB] 2019-01-26 16:27:00
    6  blob[37.22 kB] 2019-01-26 16:27:00
    7  blob[37.22 kB] 2019-01-26 16:27:00
    8  blob[37.22 kB] 2019-01-26 16:27:00
    9  blob[37.22 kB] 2019-01-26 16:27:00
    10 blob[37.22 kB] 2019-01-26 16:27:00
    11 blob[37.22 kB] 2019-01-26 16:27:00
    12 blob[37.22 kB] 2019-01-26 16:27:00
    13 blob[37.22 kB] 2019-01-26 16:27:00
    14 blob[37.22 kB] 2019-01-26 16:27:00
    15 blob[37.22 kB] 2019-01-26 16:27:00
    16 blob[38.08 kB] 2019-01-26 16:27:02
    17 blob[38.08 kB] 2019-01-26 16:27:02
    18 blob[38.08 kB] 2019-01-26 16:27:02
    19 blob[38.08 kB] 2019-01-26 16:27:02
    20 blob[38.08 kB] 2019-01-26 16:27:02
    21 blob[38.08 kB] 2019-01-26 16:27:02
    22 blob[38.08 kB] 2019-01-26 16:27:02
    23 blob[38.08 kB] 2019-01-26 16:27:02
    24 blob[38.08 kB] 2019-01-26 16:27:02
    25 blob[38.08 kB] 2019-01-26 16:27:02
    26 blob[38.08 kB] 2019-01-26 16:27:02
    27 blob[38.08 kB] 2019-01-26 16:27:02
    28 blob[38.08 kB] 2019-01-26 16:27:02
    29 blob[38.08 kB] 2019-01-26 16:27:02
    30 blob[38.08 kB] 2019-01-26 16:27:02
    31 blob[38.08 kB] 2019-01-26 16:27:02
    32 blob[38.08 kB] 2019-01-26 16:27:02
    33 blob[37.22 kB] 2019-01-26 16:27:07
    34 blob[37.22 kB] 2019-01-26 16:27:07
    35 blob[37.22 kB] 2019-01-26 16:27:07
    36 blob[37.22 kB] 2019-01-26 16:27:07
    37 blob[37.22 kB] 2019-01-26 16:27:07
    38 blob[37.22 kB] 2019-01-26 16:27:07
    39 blob[37.22 kB] 2019-01-26 16:27:07
    40 blob[38.08 kB] 2019-01-26 16:27:08
    41 blob[38.08 kB] 2019-01-26 16:27:08
    42 blob[38.08 kB] 2019-01-26 16:27:08
    43 blob[38.08 kB] 2019-01-26 16:27:08
    44 blob[38.08 kB] 2019-01-26 16:27:08
    45 blob[38.08 kB] 2019-01-26 16:27:08
    46 blob[38.08 kB] 2019-01-26 16:27:08
    47 blob[38.08 kB] 2019-01-26 16:27:09
    48 blob[38.08 kB] 2019-01-26 16:27:09
    49 blob[38.08 kB] 2019-01-26 16:27:09
    50 blob[38.08 kB] 2019-01-26 16:27:09
    51 blob[38.08 kB] 2019-01-26 16:27:09
    52 blob[38.08 kB] 2019-01-26 16:27:09

Here, we view the first 10 of 52 scores. These 10 scores were generated
by running the “verd1” template against the recording
“midEarth3\_2016-03-12\_07-00”. Notice that the columns
*manualVerifyLibraryID* and *manualVerifySpeciesID* are NA. In a
previous chapter (Scores), we illustrated how to use the interactive
function `scoresVerify()` to verify these scores, wherein a “1” signals
that the score was in fact the target signal from a target species, and
a “0” indicates a false alarm.

For demonstration purposes, instead of running `scoresVerify()`, we will
manually add *manualVerifyLibraryID* and *manualVerifySpeciesID*
verifications below for both the ‘verd1’ and ‘verd2’ templates. Later in
the chapter, these verifications later allow us to generate 2s
(confirmed surveys) for Miller-type encounter histories.

    > # Update libraryID verifications for 'verd1' template 
    > lib.vers <- c(0,0,0,0,0,1,0,1,1,1,0,1,0,1,0,1,1,1,1,1,1,1)
    > verd1.scoreIDs <- c(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,33,34,35,36,37,38,39)
    > dbExecute(conn = conx, statement =  "UPDATE scores 
    +          SET manualVerifyLibraryID = $vers 
    +          WHERE scoreID = $scoreID", 
    +          param = list(vers = lib.vers, scoreID = verd1.scoreIDs))

    [1] 22

    > # Update speciesID verifications for 'verd1' template 
    > sp.vers <- rep(1, length(verd1.scoreIDs))
    > dbExecute(conn = conx, statement =  "UPDATE scores 
    +          SET manualVerifyspeciesID = $vers 
    +          WHERE scoreID = $scoreID", 
    +         param = list(vers = sp.vers, scoreID = verd1.scoreIDs))

    [1] 22

    > # # Update libraryID verifications for 'verd2' template 
    > lib.vers <- c(1,1,1,1,1,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
    > verd2.scoreIDs <- c(16,17,18,19,20,21,22,23,24,25,26,27,28,29,30,31,32,40,41,42,43,44,45,46)
    > dbExecute(conn = conx, statement =  "UPDATE scores
    +           SET manualVerifyLibraryID = $vers 
    +           WHERE scoreID = $scoreID",
    +           param = list(vers = lib.vers, scoreID = verd2.scoreIDs))

    [1] 24

    > # # Update speciesID verifications for 'verd2' template 
    > sp.vers <- c(1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,0,1,1,1,1,1,1,1,1)
    > dbExecute(conn = conx, statement =  "UPDATE scores
    +           SET manualVerifyspeciesID = $vers 
    +           WHERE scoreID = $scoreID",
    +           param = list(vers = sp.vers, scoreID = verd2.scoreIDs))

    [1] 24

As shown, 22 records (scores) were updated for events detected by
‘verd1’, and 24 scores were updated for events detected by ‘verd2’.

Our next task is to combine verifications, annotations, and scores into
encounter histories that can be passed to the Miller model.

shapeOccupancy()
================

The `shapeOccupancy()` function converts detection data into an
encounter history for the Miller model. This encounter history will be
an N x M matrix, where N, the number of rows, is equal to the number of
study locations in a monitoring program, and M, the number of columns,
is equal to the combined total number of surveys taken across all
sampling seasons.

The encounter history matrix itself is composed of zeroes (0 - uncertain
absence), ones (1 - unconfirmed presence), and twos (2 - confirmed
presence). `shapeOccupancy()` uses either detection data directly from
the **scores** table or from the **classifications** table (recommended)
to generate 1s, and uses both **annotations** and verification data
(*manualVerifySpeciesID* and *manualVerifyLibraryID* columns in the
**scores** table) to produce 2s.

We demonstrate `shapeOccupancy()` below.

First, we view the arguments:

    > # Check out the arguments for shapeOccupancy
    > args(shapeOccupancy)

    function (db.path, table = "classifications", locationID, seasons, 
        survey.length = 1, template.list = NULL, model.list = NULL, 
        amml = NULL, cull.FA = FALSE) 
    NULL

As usual, we input the **db.path** object to the ‘db.path’ argument. In
the ‘table’ argument, we specify whether we would like our encounter
history to be generated from the classifications table
(‘classifications’) or the scores table (‘scores’). the defaul,
“classifications”, is recommended because it may reduce false positive
detections by utilizing classifications made by one or more statistical
learning models. In ‘locationID’, we must explicitly state which
locationIDs should be used to generate the encounter history – this is
intended to give the user greater ownership over which locations are
meaningful for the encounter history during the seasonal monitoring
periods, given that not all locations may be monitored during an entire
season depending on monitoring protocols in a research program. Below,
we choose locationID = ‘all’.

Next, the ‘seasons’ argument requires care. Here, we must create a list
in which we indicate the start and end dates for each “season” (primary
period) we would like to include in the occupancy model. This argument
provides maximum flexibility because the nature of a “season” may vary
based on monitoring goals and periods of closure meaningful for the
target species. Below, we indicate a list with two seasons, with the
first season extending from ‘2016-03-01’ to ‘2016-03-15’ (inclusive),
and the second season ranging from ‘2016-03-16’ to ‘2016-03-31’
(inclusive). We chose these seasons merely for demonstration within a
small dataset; they are not meaningful for Verdin life history patterns.
By specifying these dates, we assume that a site’s occupancy status will
not change within the first and second portions of March. However,
*between* the first and second portion of March, occupancy status may
change.

Next, because we have set table = ‘classifications’, we must now
construct an input to the ‘model.list’ argument. The ‘model.list’ is
another input that requires care, thought, and attention to detail from
the user. It is a nested list where each list element is named according
to a templateID that exists in the database, and where each list element
contains three elements, named ‘models’, ‘ensemble’, and ‘threshold’.
The models element should contain a character vector of statistical
learning classifier model name(s) present in your ammls/classifier.RDS
amml. Recall from the Classifications chapter that these model names
automatically encode the templateID, raw template score.threshold,
label.type, and classifier type (e.g., ‘verd1\_0.2\_libraryID\_glmnet’)
– if multiple model names are input to the ‘models’ element of
model.list, model names must match on every characteristic except
classifier. By inputting multiple classifiers, the user is indicating
that they want to aggregate those classifiers in a weighted average
ensemble method. In the ‘ensemble’ element, the user should specify a
single character string of which type of ensemble to create an encounter
history from, if using multiple models. Ensemble options are ‘accuracy’,
‘sensitivity’, ‘specificity’, ‘f1’, ‘precision’, or ‘simple’ (or NULL if
only inputting one classifier). In the example below, we will input only
a single list element, named ‘verd1’ after the verd1 template, which
contains a single model name, models = ‘verd1\_0.2\_libraryID\_glmnet’.
We will set ensemble = NULL. Thus, we are limiting observations from the
verd1 template to only classifications from the glmnet classifier.

Finally, in the ‘threshold’ element, the user must specify the
survey-level detection threshold above which an automatic ‘1’ will be
logged to signify a detection at the survey level. **Note that this
threshold is different from a template detection score.threshold.** In
the context of `shapeOccupancy()`, a threshold is a probability value
bound between 0 and 1. When using table = ‘classifications’,
`shapeOccupancy()` will compute the probability that there is *at least
one* true target signal detected during the survey period \[6\]. A
threshold value of 0.95, as chosen below, indicates that we want a
probability of at least 0.95 that there is at least one target signal
within the survey to log a 1 in the encounter history.

    > # Generate a model list object, where each list element is named after a valid templateID, 
    > # and contains elements named 'models', 'ensemble', and 'threshold':
    > mod.list <- list(
    +   verd1 = list(models = 'verd1_0.2_libraryID_glmnet',
    +                ensemble = NULL,
    +                threshold = 0.95)
    + )

After constructing our model.list object, in the ‘amml’ argument, we
point to the **amModel** library that stores our classification models.
In ‘survey.length’, we specify the number of days that should consitute
a (secondary) survey at each location. Below, we are declaring that
three days’ worth of recordings will all be lumped into a single survey
for the purposes of the occupancy model. Finally, the ‘cull.FA’ argument
grants us the option to eliminate any classification records where the
probability of target signal is less than 0.5. We are “culling” false
alarms (FA) from the dataset in that case, and they will not be used in
the probability aggregation scheme to compute whether our survey.level
detection threshold exceeds 0.95. For now, we will set this to FALSE.
With this information, a Miller-type encounter history will be produced.
(Warning: this table will produce a table with just a few 0’s and 2’s,
and a lot of NAs!)

    > # Read in our classifiers amml
    > amml <- readRDS('ammls/classifiers.RDS')
    > 
    > # Test the shapeOccupancy() function
    > shapeOccupancy(db.path = db.path,
    +                table = 'classifications', 
    +                locationID = 'all',
    +                seasons = list(season1 = c('2016-03-01', '2016-03-15'),
    +                               season2 = c('2016-03-16', '2016-03-31')),
    +                model.list = mod.list, 
    +                amml = amml, 
    +                survey.length = 3, 
    +                cull.FA = FALSE)

    Processing models from templateID verd1


    You have 50 locations, with 10 surveys at each location (total = 500 surveys). 
    Based on data in the recordings table, 496 surveys are missing and have been logged as NA. 

    Based on annotations data and verified scores data, you have confirmed a total of 3 surveys (0.6% of surveys).

    $encounter.history
                1-1 1-2 1-3 1-4 1-5 2-1 2-2 2-3 2-4 2-5
    location@1   NA  NA  NA   2  NA  NA  NA  NA  NA  NA
    location@10  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@11  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@12  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@13  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@14  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@15  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@16  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@17  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@18  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@19  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@2   NA   2  NA  NA  NA  NA  NA  NA   0  NA
    location@20  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@21  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@22  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@23  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@24  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@25  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@26  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@27  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@28  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@29  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@3   NA  NA  NA  NA  NA  NA   2  NA  NA  NA
    location@30  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@31  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@32  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@33  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@34  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@35  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@36  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@37  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@38  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@39  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@4   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@40  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@41  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@42  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@43  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@44  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@45  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@46  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@47  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@48  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@49  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@5   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@50  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@6   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@7   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@8   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@9   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA

    $seasons
    $seasons$season1
    [1] "2016-03-01" "2016-03-15"

    $seasons$season2
    [1] "2016-03-16" "2016-03-31"


    $survey.length
    [1] 3

Here, `shapeOccupancy()` has produced a list of three items: a matrix
called **encounter.history**, and the **seasons** list and
**survey.length** values we input to the function. The encounter history
is a 3 x 10 matrix (N = 3 locations x M = 10 surveys), filled in with 0,
2, or NA. Notice that there are no 1s (unconfirmed detections) in this
encounter history, and notice also the abundance of NAs in the history.
We will walk you through the causes that produced this history.

First, notice the number of columns and the column names. The column
name ‘1-1’ indicates season 1, survey 1. ‘1-2’ stands for season 1,
survey 2. ‘2-1’ stands for season 2, survey 2, and so on, all way
through ‘2-5’ (season 2, survey 5). In the list we input to the
‘seasons’ argument, list(season1 = c(‘2016-03-01’, ‘2016-03-15’),
season2 = c(‘2016-03-16’, ‘2016-03-31’)), recall that we have two
seasons, or two primary periods. Season 1, from March 1st to March 15th,
contains 15 days. Season 2, from March 16 to March 31, contains 16 days.
Recall that we chose a ‘survey.length’ of three days. A 15 day sampling
season divided by 3 days per survey = 5 surveys. A 16 day sampling
season divided by 3 days per survey = 5.3333 surveys. Because 1/3 of a
survey is not allowed, `shapeOccupancy()` will automatically tack extra
days into the last survey of the season. This function behavior behooves
users to choose season date ranges that result in relatively even survey
cuts beforehand.

Next, why are there so many NAs in this encounter history? We revisit
the sample data in the **recordings** table for a clue:

    > dbGetQuery(conn = conx, 'SELECT * FROM recordings')

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

Recall that we only have four recordings in the sample database. We have
one recording taken at location@1, two recordings at location@2, and one
recording at location@3. In this case, because our sample recording data
set is so small, we actually don’t have enough recorded data to claim
that we surveyed during most of these survey periods. Wherever this
occurs, we log NAs in the history to indicate a missing survey. To
illustrate in greater detail: survey 1-1 occurs from 2016-03-01 to
2016-03-03. We have no recordings that cover this period at any
location, so all locations are logged an NA for this survey. Survey 1-2
occurs from 2016-03-04 to 2016-03-06. We have recorded data at
location@2 during this survey period, which gives us the ability to
input a 0, 1, or 2 into row 2 (named ‘location@2’), column 2 (‘1-2’).

However, why is this survey a 2 instead of a 0 or a 1? We view the
**annotations** table below for a clue, where we note that both Bilbo
and Frodo have annotated all four of these recording files manually.

    > dbGetQuery(conn = conx, statement = 'SELECT * FROM annotations')

       annotationID                       recordingID photoID               listID speciesID      libraryID   xMin   xMax   yMin   yMax  wl ovlp      wn
    1             1 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 13.056 14.680 3.6422 5.7594 512    0 hanning
    2             2 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 16.487 18.365 3.6951 5.4947 512    0 hanning
    3             3 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_2notes 19.633 21.155 3.9598 5.0713 512    0 hanning
    4             4 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 23.287 24.606 4.0127 5.1242 512    0 hanning
    5             5 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 27.853 29.223 3.8010 5.5476 512    0 hanning
    6             6 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_2notes 32.553 33.821 3.9069 5.2301 512    0 hanning
    7             7 midEarth3_2016-03-12_07-00-00.wav    <NA>         Bilbo's List      verd    verd_2notes 36.866 38.337 3.6951 5.1771 512    0 hanning
    8             8 midEarth4_2016-03-04_06-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes  3.813  4.777 3.7481 4.9125 512    0 hanning
    9             9 midEarth4_2016-03-04_06-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 24.033 25.047 3.5364 4.7537 512    0 hanning
    10           10 midEarth4_2016-03-04_06-00-00.wav    <NA>         Bilbo's List      verd    verd_2notes 28.669 29.354 3.5364 4.5420 512    0 hanning
    11           11 midEarth4_2016-03-04_06-00-00.wav    <NA>         Bilbo's List      verd    verd_2notes 31.914 32.674 3.4305 4.5949 512    0 hanning
    12           12 midEarth4_2016-03-04_06-00-00.wav    <NA>         Bilbo's List      verd    verd_3notes 35.307 36.296 3.4834 4.5420 512    0 hanning
    13           13 midEarth4_2016-03-26_07-00-00.wav    <NA> Middle Earth Mammals    coyote coyote_general  2.767 18.502 1.4721 3.0600 512    0 hanning
    14           14 midEarth5_2016-03-21_07-30-00.wav    <NA>         Frodo's List      verd     verd_other  2.564 10.584 3.5364 6.4474 512    0 hanning
    15           15 midEarth5_2016-03-21_07-30-00.wav    <NA>         Frodo's List      verd     verd_other 23.769 41.187 3.1129 5.7594 512    0 hanning
            annotation personID           timestamp
    1  blob[ 27.87 kB] bbaggins 2018-10-27 15:02:23
    2  blob[ 27.12 kB] bbaggins 2018-10-27 15:02:39
    3  blob[ 13.70 kB] bbaggins 2018-10-27 15:02:59
    4  blob[ 11.82 kB] bbaggins 2018-10-27 15:03:05
    5  blob[ 19.89 kB] bbaggins 2018-10-27 15:03:10
    6  blob[ 14.02 kB] bbaggins 2018-10-27 15:03:24
    7  blob[ 18.21 kB] bbaggins 2018-10-27 15:03:29
    8  blob[  9.37 kB] bbaggins 2018-10-27 15:04:27
    9  blob[ 10.51 kB] bbaggins 2018-10-27 15:04:52
    10 blob[  5.74 kB] bbaggins 2018-10-27 15:05:06
    11 blob[  7.35 kB] bbaggins 2018-10-27 15:05:12
    12 blob[  8.91 kB] bbaggins 2018-10-27 15:05:24
    13 blob[206.03 kB] fbaggins 2018-10-27 15:10:49
    14 blob[187.75 kB] fbaggins 2018-10-27 15:11:40
    15 blob[372.07 kB] fbaggins 2018-10-27 15:11:57

`shapeOccupancy()` will automatically use the input templateID argument
to find the speciesID linked to that template (in this case, templateID
= ‘verd1’ is linked to the speciesID ‘verd’ for the songbird Verdin).
`shapeOccupancy()` will then identify *any* species listIDs where Verdin
is being searched (in this case, both Bilbo and Frodo have declared that
they will search for Verdin presence or absence on Bilbo’s List and
Frodo’s List, respectively). `shapeOccupancy()` will then search through
the **annotations** table to see if the target species, Verdin, is
located in any annotations on relevant survey recordings. If Verdin is
found on these recordings, the function logs a ‘2’ in the encounter
history to indicate a confirmed survey. If Verdin is NOT found by any
Verdin searcher, the function logs a ‘0’ in the encounter history.

We can also look to the **scores** table for clues about 0s, 1s, or 2s,
paying special attention to the *manualVerifySpeciesID* and
*manualVerifyLibraryID* columns. In addition to the **annotations**
table, `shapeOccupancy()` searches through the **scores** table to see
if any detected events have been manually verified for the species of
interest.

    > dbGetQuery(conn = conx, 
    +            statement = 'SELECT scoreID, recordingID, templateID, 
    +                                manualVerifyLibraryID, manualVerifySpeciesID 
    +                         FROM scores 
    +                         WHERE manualVerifySpeciesID = 1')

       scoreID                       recordingID templateID manualVerifyLibraryID manualVerifySpeciesID
    1        1 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    2        2 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    3        3 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    4        4 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    5        5 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    6        6 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    7        7 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    8        8 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    9        9 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    10      10 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    11      11 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    12      12 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    13      13 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    14      14 midEarth3_2016-03-12_07-00-00.wav      verd1                     1                     1
    15      15 midEarth3_2016-03-12_07-00-00.wav      verd1                     0                     1
    16      16 midEarth3_2016-03-12_07-00-00.wav      verd2                     1                     1
    17      17 midEarth3_2016-03-12_07-00-00.wav      verd2                     1                     1
    18      18 midEarth3_2016-03-12_07-00-00.wav      verd2                     1                     1
    19      19 midEarth3_2016-03-12_07-00-00.wav      verd2                     1                     1
    20      20 midEarth3_2016-03-12_07-00-00.wav      verd2                     1                     1
    21      21 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    22      22 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    23      23 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    24      24 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    25      25 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    26      26 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    27      27 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    28      28 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    29      29 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    30      30 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    31      32 midEarth3_2016-03-12_07-00-00.wav      verd2                     0                     1
    32      33 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    33      34 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    34      35 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    35      36 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    36      37 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    37      38 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    38      39 midEarth5_2016-03-21_07-30-00.wav      verd1                     1                     1
    39      40 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    40      41 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    41      42 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    42      43 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    43      44 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    44      45 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1
    45      46 midEarth5_2016-03-21_07-30-00.wav      verd2                     0                     1

Here, recall that we added verifications at the level of the libraryID
(*manualVerifyLibraryID*) and the speciesID (*manualVerifySpeciesID*).
In some cases, the detection was a false alarm (0) at the libraryID
level, but a target signal (1) at the speciesID level. Though we input a
model.list object focused on ‘verd1’ in our example, realize that to log
confirmed presences (2s), `shapeOccupancy()` will search for
species-level verifications for ANY templateID associated with the
target speciesID.

This brings us to an important point about `shapeOccupancy()` – it
generates encounter histories strictly at the *species-level*, and not
at the level of the libraryID. So regardless of which template is used
to generate automatic detections, `shapeOccupancy()` is working under
the hood to link this templateID to a speciesID, therefore finding ANY
species-level annotations or verifications to generate confirmed
presence (2s) in the encounter history.

Ensemble Classifications
========================

We will look at two more examples of how to use `shapeOccupancy()` with
the classifications table. Above, we used the `shapeOccupancy()` setting
table = ‘classifications’, and we input a single model to the ‘models’
element of the **mod.list** object input to the model.list argument.
However, as mentioned in Chapter 17: Classifications, we can combine the
power of multiple classifiers to make predictions about the target
signal probability of each detection. `shapeOccupancy()` runs the
`classifierEnsemble()` function to do this.

To illustrate the concept of a precision-weighted ‘ensemble’, we will
read in the classifiers amml, and then use `classifierPerformance()` to
remind ourselves how all five classifiers performed on the test data.
Pulling out a few columns, we recall that the glmnet, svmLinear, and
kknn classifiers performed best on the precision metric, each scoring a
1. If we use a precision-weighted average ensemble in
`shapeOccupancy()`, this means the glmnet, svmLinear, and kknn
classifiers have the highest “weight” in the weighted average.
Meanwhile, svmRadial performs worst on precision, with a score of 0.5;
it will have the lowest weight in the precision-weighted average.

    > # Assess model performance during the training and testing phase: 
    > performance <- classifierPerformance(amml = amml, 
    +                                      model.names = names(modelMeta(amml = amml)))
    > 
    > # Compare model performance for 5 metrics
    > performance[, c('Model', 'Accuracy', 'Sensitivity', 'Specificity', 'Precision', 'F1')]

                               Model Accuracy Sensitivity Specificity Precision     F1
    1:    verd1_0.2_libraryID_glmnet   0.8333      0.6667      1.0000    1.0000 0.8000
    2: verd1_0.2_libraryID_svmLinear   0.8333      0.6667      1.0000    1.0000 0.8000
    3: verd1_0.2_libraryID_svmRadial   0.5000      1.0000      0.0000    0.5000 0.6667
    4:        verd1_0.2_libraryID_rf   0.6667      0.6667      0.6667    0.6667 0.6667
    5:      verd1_0.2_libraryID_kknn   0.8333      0.6667      1.0000    1.0000 0.8000

In `shapeOccupancy()`, the weighted average ‘ensemble’ options are
c(‘accuracy’, ‘sensitivity’, ‘specificity’, ‘precision’, ‘f1’,
‘simple’); instead of precision, we could alternatively choose to
construct our weighted average ensemble models based on the accuracy,
sensitivity, specificity, or f1 scores. One final option is that we
could merely choose to take an unweighted average of each classifier’s
target signal probability prediction for a given observation (‘simple’).
If there are any sub-optimal performances in the set of classifier
models, like svmLinear, we can choose to leave them out of the ensemble
entirely by omitting them from the ‘models’ element of the model.list
object (or by not storing them in the classifiers.RDS amml to begin
with).

In the next example, we will keep almost all arguments the same as
before. This time, however, we will input more classifiers into the
‘models’ element of the model.list object. In the ‘ensemble’ element of
the model.list, we will indicate a weighted average ensemble type of our
choice. Below, we choose ‘precision’, which means we want to produce a
weighted average for each target signal probability based on how well
each classifier performed on the precision evaluation metric. We leave
the threshold element set at 0.95.

    > # Produce an encounter history from detection data 
    > # using a weighted average "ensemble" of classifiers
    > 
    > mod.list <- list(
    +   verd1 = list(models = c('verd1_0.2_libraryID_glmnet',
    +                           'verd1_0.2_libraryID_svmLinear',
    +                           'verd1_0.2_libraryID_svmRadial',
    +                           'verd1_0.2_libraryID_rf',
    +                           'verd1_0.2_libraryID_kknn'), 
    +                ensemble = 'precision',
    +                threshold = 0.95)
    + )
    > 
    > shapeOccupancy(db.path = db.path,
    +                table = 'classifications', 
    +                seasons = list(season1 = c('2016-03-01', '2016-03-15'),
    +                               season2 = c('2016-03-16', '2016-03-31')),
    +                model.list = mod.list, 
    +                amml = amml, 
    +                locationID = 'all',
    +                survey.length = 3, 
    +                cull.FA = FALSE)

    Processing models from templateID verd1


    You have 50 locations, with 10 surveys at each location (total = 500 surveys). 
    Based on data in the recordings table, 496 surveys are missing and have been logged as NA. 

    Based on annotations data and verified scores data, you have confirmed a total of 3 surveys (0.6% of surveys).

    $encounter.history
                1-1 1-2 1-3 1-4 1-5 2-1 2-2 2-3 2-4 2-5
    location@1   NA  NA  NA   2  NA  NA  NA  NA  NA  NA
    location@10  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@11  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@12  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@13  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@14  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@15  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@16  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@17  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@18  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@19  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@2   NA   2  NA  NA  NA  NA  NA  NA   0  NA
    location@20  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@21  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@22  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@23  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@24  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@25  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@26  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@27  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@28  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@29  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@3   NA  NA  NA  NA  NA  NA   2  NA  NA  NA
    location@30  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@31  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@32  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@33  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@34  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@35  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@36  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@37  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@38  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@39  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@4   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@40  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@41  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@42  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@43  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@44  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@45  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@46  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@47  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@48  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@49  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@5   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@50  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@6   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@7   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@8   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@9   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA

    $seasons
    $seasons$season1
    [1] "2016-03-01" "2016-03-15"

    $seasons$season2
    [1] "2016-03-16" "2016-03-31"


    $survey.length
    [1] 3

Due to how small our sample dataset is, the final outcome is the same as
in the first example. To this point, we have demonstrated using the
table = ‘classifications’ option to produce encounter histories
constructed from either a single classifier or several classifier
models.

A third option is to use classifiers constructed from multiple
templates, as signified by having additional named components of the
model.list object. We can choose different mixes of ensembles and
thresholds depending on our needs. Below, we create model.list elements
for classifiers built from both the ‘verd1’ and ‘verd2’ templates. We
also read in a sample amml named **classifiers\_amml**, which contains
pre-trained classifier models for the ‘verd2’ template (which we did not
do in Chapter 17, where we only constructed classifiers for ‘verd1’).

    > # Generate the model.list object
    > mod.list <- list(
    +   verd1 = list(models = c('verd1_0.2_libraryID_svmLinear', 
    +                           'verd1_0.2_libraryID_kknn', 
    +                           'verd1_0.2_libraryID_rf'), 
    +                ensemble = 'f1',
    +                threshold = 0.9), 
    +   verd2 = list(models = c('verd2_0.2_libraryID_glmnet', 
    +                           'verd2_0.2_libraryID_rf',
    +                           'verd2_0.2_libraryID_svmLinear',
    +                           'verd2_0.2_libraryID_svmRadial'), 
    +                ensemble = 'precision',
    +                threshold = 0.99)
    + )
    > 
    > # Read in the sample classifiers_amml, which contains classifier models
    > # for both the verd1 and verd2 templates
    > data(classifiers_amml)
    > 
    > # Run shapeOccupancy() using multiple classifiers from multiple templates
    > shapeOccupancy(db.path = db.path,
    +                table = 'classifications', 
    +                seasons = list(season1 = c('2016-03-01', '2016-03-15'),
    +                               season2 = c('2016-03-16', '2016-03-31')),
    +                model.list = mod.list, 
    +                amml = classifiers_amml, 
    +                locationID = 'all',
    +                survey.length = 3, 
    +                cull.FA = FALSE)

    Processing models from templateID verd1

    Processing models from templateID verd2


    You have 50 locations, with 10 surveys at each location (total = 500 surveys). 
    Based on data in the recordings table, 496 surveys are missing and have been logged as NA. 

    Based on annotations data and verified scores data, you have confirmed a total of 3 surveys (0.6% of surveys).

    $encounter.history
                1-1 1-2 1-3 1-4 1-5 2-1 2-2 2-3 2-4 2-5
    location@1   NA  NA  NA   2  NA  NA  NA  NA  NA  NA
    location@10  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@11  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@12  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@13  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@14  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@15  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@16  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@17  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@18  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@19  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@2   NA   2  NA  NA  NA  NA  NA  NA   0  NA
    location@20  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@21  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@22  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@23  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@24  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@25  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@26  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@27  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@28  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@29  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@3   NA  NA  NA  NA  NA  NA   2  NA  NA  NA
    location@30  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@31  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@32  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@33  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@34  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@35  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@36  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@37  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@38  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@39  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@4   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@40  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@41  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@42  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@43  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@44  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@45  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@46  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@47  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@48  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@49  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@5   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@50  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@6   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@7   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@8   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@9   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA

    $seasons
    $seasons$season1
    [1] "2016-03-01" "2016-03-15"

    $seasons$season2
    [1] "2016-03-16" "2016-03-31"


    $survey.length
    [1] 3

Generating encounter histories from the scores table
====================================================

One final option is to construct encounter histories directly from the
**scores** table instead of the **classifications** table. This option
may be suitable if users have not undergone the process of verifying
detections and training classifiers as described in Chapter 17:
Classifiers. Instead, templates are run against recordings, resulting in
records that populate the **scores** table, and encounter histories can
be generated directly from those detections.

To use this option in `shapeOccupancy()`, arguments are similar to those
in the previous examples, with a few major exceptions: first, we must
set table = ‘scores’. Secondly, the ‘model.list’, ‘ensemble’, ‘amml’,
and ‘cull.FA’ arguments can be omitted entirely, since they are not
relevant if using table = ‘scores’. Finally, instead of inputting a
model.list, this time we are inputting a template.list, with one or more
templates. Each template.list element, named according to a valid
templateID in the database, contains a single numeric value that
indicates the detection threshold. **Here, instead of an aggregated
probability as in the table = ‘classifications’ option, now this
threshold value merely stands for the actual template score detection
threshold we should use to log a detection.** For example, if using a
spectrogram cross-correlation template, we might decide to log a
detection if this record exceeds a correlation score of 0.20 or 0.22 (as
below). (If using a binary point matching template, the score might be
more like 5, or 10, or anything suitable.)

    > # Produce an encounter history from detection data using only the scores table
    > 
    > # Create a template list object with one or more valid templateIDs and score thresholds of choice
    > templ.list <- list(verd1 = 0.20, 
    +                    verd2 = 0.22)
    > 
    > # Run shapeOccupancy()
    > shapeOccupancy(db.path = db.path,
    +                table = 'scores', 
    +                seasons = list(season1 = c('2016-03-01', '2016-03-15'),
    +                               season2 = c('2016-03-16', '2016-03-31')),
    +                template.list = templ.list,
    +                model.list = NULL, 
    +                amml = NULL, 
    +                locationID = 'all',
    +                survey.length = 3, 
    +                cull.FA = FALSE)


    You have 50 locations, with 10 surveys at each location (total = 500 surveys). 
    Based on data in the recordings table, 496 surveys are missing and have been logged as NA. 

    Based on annotations data and verified scores data, you have confirmed a total of 3 surveys (0.6% of surveys).

    $encounter.history
                1-1 1-2 1-3 1-4 1-5 2-1 2-2 2-3 2-4 2-5
    location@1   NA  NA  NA   2  NA  NA  NA  NA  NA  NA
    location@10  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@11  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@12  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@13  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@14  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@15  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@16  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@17  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@18  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@19  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@2   NA   2  NA  NA  NA  NA  NA  NA   0  NA
    location@20  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@21  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@22  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@23  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@24  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@25  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@26  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@27  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@28  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@29  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@3   NA  NA  NA  NA  NA  NA   2  NA  NA  NA
    location@30  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@31  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@32  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@33  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@34  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@35  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@36  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@37  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@38  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@39  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@4   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@40  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@41  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@42  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@43  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@44  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@45  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@46  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@47  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@48  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@49  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@5   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@50  NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@6   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@7   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@8   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA
    location@9   NA  NA  NA  NA  NA  NA  NA  NA  NA  NA

    $seasons
    $seasons$season1
    [1] "2016-03-01" "2016-03-15"

    $seasons$season2
    [1] "2016-03-16" "2016-03-31"


    $survey.length
    [1] 3

Again, due to the contracted nature of our sample dataset, the results
happen to be the same in all four `shapeOccupancy()` example cases.

Notice that regardless of whether you are using the scores or
classifications table to create encounter histories, `shapeOccupancy()`
provides messages to let you know how many surveys were confirmed (based
on existing **annotations** and verification data in the **scores**
table). If the proportion of confirmed surveys is quite low, the user is
encouraged to either use `annotateRecording()` to annotate recordings,
and/or `scoresVerify()` to verify automated detections as target signals
or false alarms. Either option will increase the amount of data
`shapeOccupancy()` can use to produce confirmed detections (2s) in the
encounter history.

Because annotations for photos are also included in the **annotations**
table, it is theoretically possible to create encounter histories based
on photographs, but `shapeOccupancy()` does not currently implement this
functionality.

Running RPresence for Miller model analysis
===========================================

Once we have generated encounter histories with `shapeOccupancy()`, we
can pass the output to RPresence to analyze the data with the Miller
model. Below, we run `shapeOccupancy()` and store the output as an
object named **eh.list**. We set locationID = ‘all’ to include all 50
locations in the workflow:

    > eh.list <- shapeOccupancy(db.path = db.path,
    +                         table = 'scores', 
    +                         seasons = list(season1 = c('2016-03-01', '2016-03-15'),
    +                                        season2 = c('2016-03-16', '2016-03-31')),
    +                         template.list = templ.list,
    +                         model.list = NULL, 
    +                         amml = NULL, 
    +                         locationID = 'all',
    +                         survey.length = 3, 
    +                         cull.FA = FALSE)


    You have 50 locations, with 10 surveys at each location (total = 500 surveys). 
    Based on data in the recordings table, 496 surveys are missing and have been logged as NA. 

    Based on annotations data and verified scores data, you have confirmed a total of 3 surveys (0.6% of surveys).

Above, we used `shapeOccupancy()` to create an **eh.list** object.

However, because our dataset is so small and insufficient for
demonstration, we will replace the output with a **simulated encounter
history** using the function `occupancySim()`. This function is a simple
intercept-model simulator for the single-species false positive dynamic
occupancy model (the Miller model). It does not accommodate covariates.
Users may input a desired number of sites (‘n.sites’), seasons
(‘n.seasons’), and ‘surveys.per.season’. In ‘psi’, input the desired
probability of occupancy in the first season; in ‘gamma’, the
probability of colonization of an unoccupied site; and in ‘epsilon’, the
probability of extinction from an occupied site. In ‘p11’, input a value
for detection probability given presence; in ‘p10’, the probability of a
false positive detection at an unoccupied site; and in ‘b’, the
probability a detection will be certain, conditional on detecting the
species at an occupied site.

    > # set a random number seed
    > set.seed(201)
    > 
    > # create a simulated encounter history with 100 sites
    > sim.eh <- occupancySim(n.sites = 100, 
    +                        n.seasons = 2, 
    +                        surveys.per.season = 5,
    +                        psi = 0.5, 
    +                        gamma = 0.15, 
    +                        epsilon = 0.15,
    +                        p11 = 0.8,
    +                        p10 = 0.05,
    +                        b = 0.05)

    Requested psi: 0.5. Simulated: 0.48.

    Requested gamma: 0.15. Simulated: 0.175.

    Requested epsilon: 0.15. Simulated: 0.155.

    Requested p11: 0.8. Simulated: 0.835.

    Requested p10: 0.05. Simulated: 0.041.

    Requested b: 0.05. Simulated: 0.045.

`occupancySim()` returns a matrix where the number of rows is equal to
‘n.sites’, and the number of columns is equal to
‘n.seasons’\*‘surveys.per.season’. Notice that because of the random
nature of simulating data, the final dataset’s parameters are not
exactly equal to the requested parameter values; increasing sample size
will generally reduce this difference. Cells are populated with either a
0, 1, or 2. Row names indicate generic location names. Again, column
names follow the pattern of ‘season’-‘survey’; the column name ‘1-1’
indicates season 1, survey 1. ‘1-2’ stands for season 1, survey 2, and
so on. `occupancySim()` also returns messages comparing the
user-specified values against the actual simulated values (which may
differ substantially if given a low value of ‘n.sites’). Below, we view
the first few records of **sim.eh** to confirm its format:

    > head(sim.eh)

               1-1 1-2 1-3 1-4 1-5 2-1 2-2 2-3 2-4 2-5
    location@1   1   1   1   0   1   1   1   1   1   1
    location@2   0   0   0   0   0   1   1   1   1   0
    location@3   0   0   0   0   0   0   0   1   0   0
    location@4   0   0   0   0   0   0   0   0   0   0
    location@5   1   1   1   1   0   1   1   1   1   1
    location@6   0   0   0   0   1   0   0   0   0   0

Finally, we use RPresence functions to fit a Miller et al. 2013 dynamic
occupancy model with no covariates.

First, we use the RPresence function `createPao()` to generate a PAO
(proportion of area occupied) file for input to PRESENCE. The ‘data’
argument takes a raw encounter history matrix as input. Below, we have
directly input our simulated encounter history, **sim.eh**, but note
that in a typical workflow, this would generally be your
**eh.list$encounter.history** object. In ‘nsurveyseason’, we specify the
number of surveys in each season; in our case, there are 5 per season.
Into the ‘unitnames’ argument, we input the rownames of the encounter
history, taking care to ensure that they are in the same order as the
sites in the encounter history matrix.

    > # Load RPresence
    > library(RPresence)
    > 
    > # Create pao
    > one.pao <- createPao(data = sim.eh,             
    +                      nsurveyseason = rep(5, 2), 
    +                      unitnames = rownames(sim.eh)) 

Next, we create formulas for all six parameters of the Miller model, and
turn them into R data type “formulas” using lapply(form.list,
as.formula). Finally, we use `occMod()`, inputting the **formulas**
object to the ‘model’ argument and **one.pao** to ‘data’. Under ‘type’,
we indicate ‘do.fp’ (which stands for dynamic occupancy false
positives). We use the ‘randinit’ argument to tell PRESENCE to use 9
different starting values to help it find the top of the likelihood
function. Lastly, we can give the output file a name in the ‘outfile’
argument. See [RPresence/PRESENCE
documentation](https://www.mbr-pwrc.usgs.gov/software/presence.html) for
more details.

    > # Create a list of formulae for the Miller intercept model
    > form.list <- list('psi ~ 1', 
    +                   'gamma ~ 1', 
    +                   'epsilon ~ 1',
    +                   'p11 ~ 1', 
    +                   'p10 ~ 1', 
    +                   'b ~ 1')
    > 
    > # Convert the formula list to an object of class formula
    > formulas <- lapply(form.list, as.formula)
    > 
    > # Run the RPresence occMod function; save the output as a model called 'm0'
    > m0 <- occMod(model = formulas,
    +              data = one.pao,
    +              type = 'do.fp',
    +              randinit = 9,
    +              outfile = 'm0')
    > 
    > # Look at the structure of the resulting model output
    > str(m0, max.level = 1)

    List of 12
     $ modname    : chr "psi()gamma()epsilon()p11()p10()b()"
     $ model      :List of 4
     $ dmat       :List of 2
     $ data       :List of 15
      ..- attr(*, "class")= chr "pao"
     $ outfile    : chr "m0"
     $ neg2loglike: num 986
     $ npar       : int 6
     $ aic        : num 998
     $ beta       :List of 9
     $ real       :List of 6
     $ warnings   :List of 2
     $ version    :List of 2
     - attr(*, "class")= chr [1:2] "occMod" "soFp"

RPresence returns a list of outputs, which is packed full of information
about the analysis. The authors have written functions that allow us to
extract key pieces of information easily. The names of these functions
can be found with the `methods()` function:

    > methods(class = class(m0))

    [1] coef      fitted    predict   residuals summary  
    see '?methods' for accessing help and source code

We have five methods at our disposal. We can use the `summary()` method
to view basic outputs, such as the model likelihood and AIC results.
Notice that this basic Miller model estimates 6 parameters:

    > summary(m0)

    Model name=psi()gamma()epsilon()p11()p10()b()
    AIC=998.3477
    -2*log-likelihood=986.3477
    num. par=6

To view real parameter estimates (on the probability scale), we can
extract the “real” list element from our m0 object. Below, we will only
extract the real parameter estimates for the first location because all
locations have the exact same parameter estimates:

    > lapply(m0$real, function(x) x[1, 'est'])

    $psi
    [1] 0.4816587

    $gamma
    [1] 0.1752029

    $epsilon
    [1] 0.1725935

    $p11
    [1] 0.8486087

    $p10
    [1] 0.04081646

    $b
    [1] 0.05339807

Now, we compare these estimates with the parameters that were actually
simulated in the `simOccupany` function:

-   psi requested = 0.5; simulated = 0.48
-   gamma requested = 0.15; simulated = 0.175
-   epsilon requested = 0.15; simulated = 0.155
-   p11 requested = 0.8; simulated = 0.835
-   p10 requested = 0.05; simulated = 0.041
-   b requested = 0.5; simulated = 0.045

Thus, given the simulated encountered history and the actual rates
within, the Miller model was able to do a very good job at finding these
parameter estimates; see also \[3\]. As with any modeling exercise, we
should take care to formally assess how well the model fits the data.
That is beyond our scope here, however.

If we decide we have created a useful occupancy model that we would like
to store for future use, we can convert it into an **amModel** object
and add it to the AMModel library that we created many chapters ago to
store our dynamic false positives occupancy model outputs. This library
is stored in in the **ammls** directory under ammls/do\_fp.RDS. Below,
we demonstrate code for saving a useful model to the do\_fp AMModels
library. We will be able to use this model in the future and update it
as needed to evaluate our progress toward our Verdin monitoring
objective through time.

    > # Read do_fp amml into R: 
    > do.fp.amml <- readRDS('ammls/do_fp.RDS')
    > 
    > # Turn m0 into an amModel
    > am.model <- amModel(model = m0, comment = '')
    > 
    > # Turn am.model into a named list for insertAMModelLib
    > am.model.list <- list(verd_occupany = am.model)
    > 
    > # Insert into amml:
    > do.fp.amml <- insertAMModelLib(models = am.model.list, 
    +                                amml = do.fp.amml)
    > 
    > # Save to amml folder:
    > saveRDS(do.fp.amml, 'ammls/do_fp.RDS')

This occupancy model and other models like it may have great utility for
a research or management program. We have provided just one example of
how the data stored in the **classifications** table of the AMMonitor
database can be analyzed to address specific research questions.

You may recall from Chapter 5 that we have an objective named
‘verd\_occupancy’, which is to maintain current Verdin occupancy at a
standard of 0.40, with a minimum of 0.45 and a maximum of 0.55.

    > dbGetQuery(conn = conx,
    +            statement = 'SELECT * 
    +                         FROM objectives')

         objectiveID       listID speciesID                                   objective indicator       units direction  min  max standard
    1       midEarth Middle Earth      <NA>                Conserve native biodiversity      <NA>        <NA>      <NA>   NA   NA       NA
    2 btgn_occupancy         <NA>      btgn Maximize Black-tailed Gnatcatcher occupancy       Psi Probability  Maximize   NA   NA       NA
    3 ecdo_occupancy         <NA>      ecdo   Minimize Eurasian Collared-dove occupancy       Psi Probability  Minimize   NA   NA     0.25
    4 verd_occupancy         <NA>      verd                   Maintain Verdin Occupancy       Psi Probability  Maintain 0.35 0.45     0.40
                                   narrative
    1 Narrative for this objective goes here
    2 Narrative for this objective goes here
    3 Narrative for this objective goes here
    4 Narrative for this objective goes here

In our next chapter, we will use our Miller model to assess the state of
a system (verdin occupancy rate), and compare it to the verdin
management objective.

Chapter Summary
===============

This chapter described a workflow for moving from automated target
signal detections to dynamic occupancy models that accommodate false
positives (as in \[2\]). The `shapeOccupancy()` function can be used to
generate encounter histories formatted for the Miller model.
`shapeOccupancy()` searches the **classifications** or **scores** tables
in an AMMonitor database, along with the **annotations** table, to
produce 0s, 1s, and 2s in the Miller model encounter history, with a
variety of options for aggregating the data. Encounter histories from
`shapeOccupancy()` can be fit in the RPresence function `occMod()` to
estimate parameters. The `occupancySim()` function offers an option for
simulating Miller model encounter histories that can be used to test the
workflow. `shapeOccupancyTemporals()` and `shapeOccupancySpatials()`
allow temporal and spatial covariates to be included in calls to
`occMod()`. Useful models can be saved in the **do\_fp** AMModels
library of the **ammls** directory, and called into action through time
to track progress toward monitoring objectives.

Chapter References
==================

1. MacKenzie D, Nichols J, James Hines nad Melinda Knutson, Franklin A.
Estimating site occupancy, colonization, and local extinction when a
species is detected imperfectly. Ecology. 2003;84: 2200–2207.

2. Miller D. A., Nichols J. D., Gude J. A., Rich L. N., Podruzny K. M.,
Hines J. E., et al. Determining occurrence dynamics when false positives
occur: Estimating the range dynamics of wolves from public survey data.
PLoS one. 2013;8: e65808.

3. Balantic C, Donovan T. AMMonitor: Remote monitoring of biodiversity
in an adaptive framework. R package pending submission to CRAN;

4. Hines J. PRESENCE: Software to estimate patch occupancy and related
parameters (version 12.10) \[Internet\]. U.S. Geological Survey,
Patuxent Wildlife Research Center; 2018. Available:
<https://www.mbr-pwrc.usgs.gov/software/presence.html>

5. Hines J. RPresence for presence: Software to estimate patch occupancy
and related parameters (version 12.10) \[Internet\]. U.S. Geological
Survey, Patuxent Wildlife Research Center; 2018. Available:
<https://www.mbr-pwrc.usgs.gov/software/presence.html>

6. Balantic CM, Donovan TM. Statistical learning mitigation of false
positives from template-detected data in automated acoustic wildlife
monitoring. Bioacoustics. Taylor & Francis; 2019;0: 1–26.
doi:[10.1080/09524622.2019.1605309](https://doi.org/10.1080/09524622.2019.1605309)