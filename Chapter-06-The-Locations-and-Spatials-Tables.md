<div><img src="ammonitor-footer.png" width="1000px" align="center"></div>

-   [Chapter Introduction](#chapter-introduction)
-   [The Locations Table](#the-locations-table)
-   [The Spatials Table](#the-spatials-table)
    -   [Create a “SpatialPointsDataFrame” of monitoring
        locations](#create-a-spatialpointsdataframe-of-monitoring-locations)
    -   [Create a “SpatialPolygons” study area
        shapefile](#create-a-spatialpolygons-study-area-shapefile)
    -   [Create a “RasterLayer” raster](#create-a-rasterlayer-raster)
-   [The Locations Table in Access](#the-locations-table-in-access)
-   [The Spatials Table in Access](#the-spatials-table-in-access)
-   [Chapter Summary](#chapter-summary)
-   [Chapter References](#chapter-references)

Chapter Introduction
====================

This chapter covers the **locations** and **spatials** tables and how
they are used in a monitoring program. Connections to these tables can
be used to track monitoring locations and associated GIS spatial data.

As in past chapters, we will use `dbCreateSample()` to create a database
called “Chap6.sqlite”, which will be stored in a folder (directory)
called **database** within the **AMMonitor** main directory, which
should be your working directory in R. Recall that `dbCreateSample()`
generates all tables of an **AMMonitor** database, and then
pre-populates sample data into tables specified by the user. For
demonstration purposes in this chapter, we will only pre-populate the
**people** and **locations** tables. The **spatials** table will start
out empty, and we will populate it ourselves later in the chapter.

``` r
# Create a sample database for this chapter
dbCreateSample(db.name = "Chap6.sqlite", 
               file.path = paste0(getwd(),"/database"), 
               tables =  c("people", "locations"))
```

    ## An AMMonitor database has been created with the name Chap6.sqlite which consists of the following tables:

    ## accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals

    ## 
    ## Sample data have been generated for the following tables: 
    ## people, locations

Next, we initialize a character object, **db.path**, that holds the
database’s full file path. We connect to the database with RSQLite’s
`dbConnect()` function, where we must identify the SQLite driver in the
‘drv’ argument:

``` r
# Establish the database file path as db.path
db.path <- paste0(getwd(), '/database/Chap6.sqlite')

# Connect to the database
conx <- RSQLite::dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
```

Finally, we send a SQL statement that will enforce foreign key
constraints within the database.

``` r
# Turn the SQLite foreign constraints on
RSQLite::dbSendQuery(conn = conx, statement = "PRAGMA foreign_keys = ON;")
```

    ## <SQLiteResult>
    ##   SQL  PRAGMA foreign_keys = ON;
    ##   ROWS Fetched: 0 [complete]
    ##        Changed: 0

Now we are ready to begin.

The Locations Table
===================

The **locations** table tracks all locations of monitoring interest. The
function `dbTables()` provides a summary of the field names and data
types in the **locations** table.

``` r
# Look at information about the locations table
dbTables(db.path = db.path, table = "locations")
```

    ## $locations
    ##    cid        name         type notnull dflt_value pk comment
    ## 1    0  locationID VARCHAR(255)       1         NA  1        
    ## 2    1        type VARCHAR(255)       0         NA  0        
    ## 3    2         lat         REAL       1         NA  0        
    ## 4    3        long         REAL       1         NA  0        
    ## 5    4       datum   VARCH(255)       0         NA  0        
    ## 6    5 description         TEXT       0         NA  0        
    ## 7    6     address VARCHAR(255)       0         NA  0        
    ## 8    7        city VARCHAR(255)       0         NA  0        
    ## 9    8       state VARCHAR(255)       0         NA  0        
    ## 10   9     country VARCHAR(255)       0         NA  0        
    ## 11  10          tz VARCHAR(255)       1         NA  0        
    ## 12  11    personID VARCHAR(255)       0         NA  0

Note that the locations table has 12 fields, with a mix of VARCHAR,
TEXT, REAL (numeric), and INTEGER data. The *locationID* serves as the
primary key, and the *locationID*, *lat*, *long*, and *tz* are each
required fields.

Previous chapters have covered CRUD operations for creating, reading,
updating, or deleting records from a table. These operations are
applicable to all tables. Moving forward, we will focus on the contents
of the sample tables rather than reviewing CRUD operations for each
table.

As always, we can view records in the sample **locations** table using
either `qry()`, `dbReadTable()`, or `dbGetQuery()`, depending on our
needs with respect to the size of the table, how many records we want to
read in, and whether we want to interact via a **conx** object or a
**db.path** object:

``` r
# Return the first 5 records from the locations table (printed as a tibble)
RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM locations LIMIT 5")
```

    ##   locationID               type      lat      long datum description address city     state      country                  tz personID
    ## 1 location@1 Monitoring station 33.62687 -115.1551 WGS84        <NA>    <NA> <NA>    Gondor Middle Earth America/Los_Angeles bbaggins
    ## 2 location@2 Monitoring station 33.57669 -114.8350 WGS84        <NA>    <NA> <NA> The Shire Middle Earth America/Los_Angeles fbaggins
    ## 3 location@3 Monitoring station 33.60673 -115.2148 WGS84        <NA>    <NA> <NA>    Gondor Middle Earth America/Los_Angeles fbaggins
    ## 4 location@4 Monitoring station 33.67328 -115.0898 WGS84        <NA>    <NA> <NA>    Gondor Middle Earth America/Los_Angeles fbaggins
    ## 5 location@5 Monitoring station 33.52128 -115.2446 WGS84        <NA>    <NA> <NA>    Mordor Middle Earth America/Los_Angeles fbaggins

Our sample data set contains 50 locations, but above we retrieve only
the first five records. The *locationID* can be any identifier we want.
Here, we chose basic location names like location@1 and location@2, but
*locationID* names are chosen at the discretion of the user so long as
they are unique. In the *type* column, we have indicated that each
location is a monitoring station, but this column is flexible and could
contain any type of location one wishes to track, such as weather
stations or radar stations.

The latitudes and longitudes are tracked in the *lat* and *long*
columns, respectively. These coordinates are fairly useless unless you
know the coordinate reference system (crs). As explained at
<a href="http://rspatial.org/spatial/rst/1-introduction.html" class="uri">http://rspatial.org/spatial/rst/1-introduction.html</a>:
“A very important aspect of spatial data is the coordinate reference
system (CRS) that is used. For example, a location of (140, 12) is not
meaningful if you do know where the origin is and if the x-coordinate is
140 meters, kilometers, or perhaps degrees away from it (in the x
direction). The earth has an irregular spheroid-like shape. The natural
coordinate reference system for geographic data is longitude/latitude.
This is an angular system. For a given location on earth, obviously we
cannot actually measure these angles. But we can estimate them. To do
so, you need a model of the shape of the earth. Such a model is called a
‘datum’. The most commonly used datum is WGS84 (World Geodesic System
1984). So the basic way to record a location is a coordinate pair in
degrees and a reference datum.” We will revisit coordinate reference
systems later in the chapter.

Columns for *description*, *address*, *city*, *state*, and *country* are
not required but may be useful to some users. The *tz* column is
required, and must contain an [Olson names-formatted time
zone](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List)
that lets R know the timezone of the location. [Read more about
timezones in
R](http://stat.ethz.ch/R-manual/R-devel/library/base/html/timezones.html).

The *personID* column is also not required. The intention here is to
provide a means for associating a person with a location, such as a
landowner or the primary person responsible for the monitoring station.
Note that the *personID* is a foreign key that links to the **people**
table.

The mapping of the *personID* field can be confirmed with the following
SQLite statement.

``` r
# Return foreign key information for the locations table
RSQLite::dbGetQuery(conn = conx, statement = "PRAGMA foreign_key_list(locations);")
```

    ##   id seq  table     from       to on_update on_delete match
    ## 1  0   0 people personID personID   CASCADE NO ACTION  NONE

The field *personID* in the table **people** references the field
*personID* in the **locations** table. Again, notice the default action
of CASCADE on update and NO ACTION on delete.

The Spatials Table
==================

The **spatials** table *points* to spatial data associated with a
monitoring project, such as rasters or shapefiles; it does not store the
files themselves (in **AMMonitor**, the actual files should be stored in
the **spatials folder** as described below).

The function `dbTables()` provides a summary of the field names and data
types in the **spatials** table.

``` r
# Look at information about the spatials table
dbTables(db.path = db.path, table = "spatials")
```

    ## $spatials
    ##   cid        name         type notnull dflt_value pk comment
    ## 1   0   spatialID VARCHAR(255)       1         NA  1        
    ## 2   1        type VARCHAR(255)       0         NA  0        
    ## 3   2       class VARCHAR(255)       0         NA  0        
    ## 4   3    filepath VARCHAR(255)       0         NA  0        
    ## 5   4 description         TEXT       0         NA  0

Note that the default **spatials** table has five fields, with a mix of
data types. The *spatialID* serves as the primary key, and is the only
required field. This is often the name of the spatial file, minus the
file extension. The *type* field can be “raster” or “shapefile”, or any
other designation. If the file is stored as an R object (as we will
illustrate), the *class* column can be used to store the spatial
object’s class. The *filepath* stores either the full file path, or the
relative file path from the user’s working directory to the file. Users
can add additional metadata fields at their discretion.

We assume readers have employed the **AMMonitor** file directory
structure created by the function `ammCreateDirectories()` (Chapter 1:
Introduction). The working directory is the main **AMMonitor**
directory, and subdirectories include a folder called **database**
(which houses the SQLite database), as well as a folder called
**spatials**. The spatials directory is where we will store the actual
spatial files used in the examples below.

<kbd>

<img src="Chap6_Figs/directories.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 6.1. All spatial layers may be stored in the spatial directory
> as RDS files.*

In this section, we will illustrate how spatial files can be stored in
the **spatials directory**, and how a spatial file’s metadata can be
added to the **AMMonitor** database table named **spatials**.

Users new to spatial analysis in R may consult these helpful tutorials:

-   <a href="http://www.rspatial.org/" class="uri">http://www.rspatial.org/</a>
-   <a href="https://www.earthdatascience.org/courses/earth-analytics/spatial-data-r/" class="uri">https://www.earthdatascience.org/courses/earth-analytics/spatial-data-r/</a>
-   <a href="http://www.rpubs.com/cengel24" class="uri">http://www.rpubs.com/cengel24</a>

For our spatial analyses, we will load and use the R packages **sp**
\[1\] and **raster** \[2\].

``` r
# Load packages used for spatial analysis
library(sp)
library(raster)
library(XML)
```

Create a “SpatialPointsDataFrame” of monitoring locations
---------------------------------------------------------

For our first example, we collect information stored in the
**locations** table to generate a shapefile of points. The **sp**
package function `SpatialPointsDataFrame()` can be used create an object
of class **SpatialPointsDataFrame**.

``` r
# Read in the locations data as a table
locs <- RSQLite::dbReadTable(conn = conx, name = 'locations')

# Convert to spatialPointsDataFrame
# For the coords argument, specify long (x) before lat (y)
study_locations <- sp::SpatialPointsDataFrame(
                    coords = locs[,c('long','lat')], 
                    data = locs, 
                    proj4string = CRS("+proj=longlat +datum=WGS84"))

# Look at the structure of this shapefile
str(object = study_locations, max.level = 2)
```

    ## Formal class 'SpatialPointsDataFrame' [package "sp"] with 5 slots
    ##   ..@ data       :'data.frame':  50 obs. of  12 variables:
    ##   ..@ coords.nrs : num(0) 
    ##   ..@ coords     : num [1:50, 1:2] -115 -115 -115 -115 -115 ...
    ##   .. ..- attr(*, "dimnames")=List of 2
    ##   ..@ bbox       : num [1:2, 1:2] -115.3 33.5 -114.8 33.7
    ##   .. ..- attr(*, "dimnames")=List of 2
    ##   ..@ proj4string:Formal class 'CRS' [package "sp"] with 1 slot

As shown, an object of class **SpatialPointsDataFrame** is an S4 object
with 5 slots. This is an R object containing spatial points. The
attribute table is stored in the slot called **data**; the point
coordinates are stored in the **coords** slot, the bounding box is
stored in the **bbox** slot, and the coordinate reference and projection
information is stored in the **proj4string** slot as an object of class
CRS (Coordinate Reference System). Here, we use package **sp**’s upper
case `CRS()` function to create this object, which interfaces with
[PROJ.4](https://proj4.org/) software that allows one coordinate
reference system to be transformed to another.

The lower case `proj4string()` method provides a simple way to retrieve
the coordinate reference and projection information stored in the
**proj4string** slot.

``` r
# Use the proj4string method to return the CRS from study_locations
sp::proj4string(study_locations)
```

    ## [1] "+proj=longlat +datum=WGS84 +ellps=WGS84 +towgs84=0,0,0"

This string is an example of a “PROJ.4 string”, which provides critical
information about the spatial layer’s projection, datum, and coordinate
system, and is based on the PROJ.4 system. See
[proj4.org](https://proj4.org/usage/quickstart.html) and the [UCSB R
Spatial Guide to
CRS](https://www.nceas.ucsb.edu/~frazier/RSpatialGuides/OverviewCoordinateReferenceSystems.pdf)
for additional details.

The string contains + signs to indicate tags used by PROJ.4, but not
every spatial object will contain every type of tag:

-   +proj specifies the projection (e.g. “longlat”, “utm”, or “aea”).
-   +datum refers to the 0,0 reference for the coordinate system used in
    the projection (e.g., WGS84, NAD83)
-   +units specifies the units; m indicates meters.
-   +ellps conveys the ellipsoid (how the earth’s roundess is
    calculated).
-   +towgs serves as a conversion factor, necessary if a datum
    conversion is required.

We created our **study\_locations** object with the WGS84 datum because
this datum is often used with GPS systems. However, for this tutorial,
we actually want to transform our object into a different coordinate
reference system so that it will align with a raster layer introduced
later on in the chapter.

Next, we transform spatial objects with the `spTransform()` function.
The ‘x’ argument takes the **study\_locations** object, or the object to
be transformed. In the ‘CRSobj’ argument, we provide a coordinate
reference system object containing the proj4string for our desired
reference. We do this below, indicating that we aim to transform the
current CRS to “+init=epsg:3310”:

``` r
# Reproject the shapefile to CRS EPSG:3310
study_locations <- sp::spTransform(x = study_locations, 
                               CRSobj = CRS("+init=epsg:3310")
                               )
```

The [Spatial Reference List](http://spatialreference.org/ref/) provides
a comprehensive record of CRS options, and epsg:3310 is one of them.
Passing this value to the CRS function creates the PROJ.4 string
associated with epsg:3310:

``` r
CRS("+init=epsg:3310")
```

    ## CRS arguments:
    ##  +init=epsg:3310 +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m +no_defs +ellps=GRS80
    ## +towgs84=0,0,0

Thus, we have reprojected the **study\_locations** shapefile to a new
datum (NAD83) for Middle Earth. The units are in meters, and the
ellipsoid is calculated with the Geodetic Reference System 1980. When
mapped, the projection is Albers Equal Area.

We `plot()` the transformed object to see our study locations:

``` r
# Plot the locations
plot(study_locations, xlab = "x coordinate - longitude", 
     ylab = "y coordinate - latitude")
```

<img src="Chap6_Figs/unnamed-chunk-17-1.png" style="display: block; margin: auto auto auto 0;" />

Finally, we store this object as an RDS file within the **spatials
directory** for future use.

``` r
# Save the shapefile as an RDS file
saveRDS(object = study_locations, file = 'spatials/study_locations.RDS')
```

Notice the naming convention used in this example. We saved the object
**study\_locations** as an RDS file with the same name. You may
alternatively store the object as an RData file. When loaded, the object
will appear in R’s environment with the original object name. However,
we use RDS files in practice because they can be called into R and
assigned any name.

Before continuing, we add a record to the **AMMonitor** SQLite database
**spatials** table to document our new spatial layer.

``` r
# Create a data.frame with study locations metadata
add.sites <- data.frame(spatialID = 'study_locations',
                        type = 'shapefile',
                        class = 'SpatialPointsDataFrame',
                        filepath = 'spatials/study_locations.RDS',
                        description = "Study locations point layer for the Middle Earth monitoring program.")

# Add the record to the spatials database table 
RSQLite::dbWriteTable(conn = conx, name = 'spatials', value = add.sites,
             row.names = FALSE, overwrite = FALSE,
             append = TRUE, header = FALSE)
```

Create a “SpatialPolygons” study area shapefile
-----------------------------------------------

As a second example, we will now create a simple polygon and store it as
a second shapefile for the Middle Earth monitoring program. This simple
polygon will encompass all of the monitoring locations, with an
additional buffer.

Invoking the `bbox()` function yields the coordinates that encompass all
of the points within **study\_locations**:

``` r
# Extract the bounding box coordinates
coords <- sp::bbox(study_locations)

# Look at the coordinates
coords
```

    ##            min       max
    ## long  432121.6  480861.6
    ## lat  -489907.7 -463886.8

The coordinates are returned as a matrix that shows the minimum and
maximum longitude (x coordinates) and latitude (y coordinates). Notice
that because we transformed **study\_locations** into a new projection,
the long and lat values now look different from what we are familiar
with in the database **locations** table. We will add a buffer to these
coordinates so that our study area encompasses not only each study
location, but a cushion of space beyond them.

``` r
# Add a buffer to minimum
coords[,'min'] <- coords[,'min'] - 3000 

# Add a buffer to the maximum
coords[,'max'] <- coords[,'max'] + 3000
```

We then use the package **raster**’s `extent()` function, in conjunction
with the `as()` coercion function, to convert our coordinates to an
object of class **SpatialPolygons**:

``` r
# Convert to a polygon using the raster package extent function
study_area <- as(object = raster::extent(coords), 
                 Class = "SpatialPolygons")

# Show the metadata
study_area
```

    ## class       : SpatialPolygons 
    ## features    : 1 
    ## extent      : 429121.6, 483861.6, -492907.7, -460886.8  (xmin, xmax, ymin, ymax)
    ## coord. ref. : NA

As shown, this is an object of class **SpatialPolygons**. Note that the
coordinate reference system is missing from this S4 object. We first
need to fill in the coordinate referenence information with the
`proj4string()` function. Then, we can plot the study locations and
extent objects together to confirm that they align spatially.

``` r
# Assign the CRS
sp::proj4string(study_area) <- sp::CRS("+init=epsg:3310")

# Plot the objects together to confirm alignment
plot(study_area, 
     main = "Middle Earth Study Area and Monitoring Locations")

plot(study_locations, add = TRUE)
```

<img src="Chap6_Figs/unnamed-chunk-23-1.png" style="display: block; margin: auto auto auto 0;" />

We can then save the finalized object as an RDS file.

``` r
# Save the object as an RDS file
save(study_area, file = "spatials/study_area.RDS")
```

Now we have two shapefiles in our **spatials directory** associated with
the Middle Earth monitoring program. We need to add our second
shapefile’s information to the **spatials** table in the database.

``` r
# Create data.frame with data to be inserted to the spatials table
add.boundary <- data.frame(spatialID = 'study_area',
                           type = 'shapefile',
                           class = 'SpatialPolygons',
                           filepath = 'spatials/study_area.RDS',
                           description = "Polygon outlining the Middle Earth Study Area.")

# Add the record to the spatials database table 
RSQLite::dbWriteTable(conn = conx, name = 'spatials', value = add.boundary,
                      row.names = FALSE, overwrite = FALSE,
                      append = TRUE, header = FALSE)
```

Create a “RasterLayer” raster
-----------------------------

As a final example of working with spatial files, we will create a
spatial object of class **RasterLayer** that will cover the study area.
Here, our raster will consist of 400 pixels, each with a random number
from a standard normal distribution (mean = 0, sd = 1). First, we create
a matrix of numbers, and then use the `raster()` function to convert the
matrix to a raster.

``` r
# Set a random number seed (for reproducibility)
set.seed(100)

# Create a 20 row * 20 column matrix
data <- matrix(rnorm(n = 400, mean = 0, sd = 1),
               nrow = 20, ncol = 20)

# Turn the matrix into a raster
study_raster <- raster::raster(data)

# Show a summary
study_raster
```

    ## class       : RasterLayer 
    ## dimensions  : 20, 20, 400  (nrow, ncol, ncell)
    ## resolution  : 0.05, 0.05  (x, y)
    ## extent      : 0, 1, 0, 1  (xmin, xmax, ymin, ymax)
    ## coord. ref. : NA 
    ## data source : in memory
    ## names       : layer 
    ## values      : -3.020814, 3.304151  (min, max)

This raster is an R object of type **RasterLayer**. It consists of 400
cells (ncell), with a minimum value of -3.020814 and maximum value of
3.304151. These values can represent any sort of variable of interest to
the Middle Earth Monitoring team. For example, the numbers may represent
biomass, road density, or risk of Orc attack. Notice that the raster has
no coordinate reference system, and also no extent. We will need to
assign these.

``` r
# Set the extent to the study_area bounding box
raster::extent(study_raster) <- sp::bbox(study_area)

# Assign a projection to this raster
raster::projection(study_raster) <- sp::CRS("+init=epsg:3310")

# Project the raster
study_raster2 <- raster::projectRaster(from = study_raster, crs = sp::CRS("+init=epsg:3310"))

# Confirm projection has been assigned
study_raster2
```

    ## class       : RasterLayer 
    ## dimensions  : 26, 24, 624  (nrow, ncol, ncell)
    ## resolution  : 2740, 1600  (x, y)
    ## extent      : 423641.6, 489401.6, -497686.8, -456086.8  (xmin, xmax, ymin, ymax)
    ## coord. ref. : +init=epsg:3310 +proj=aea +lat_1=34 +lat_2=40.5 +lat_0=0 +lon_0=-120 +x_0=0 +y_0=-4000000 +datum=NAD83 +units=m +no_defs +ellps=GRS80 +towgs84=0,0,0 
    ## data source : in memory
    ## names       : layer 
    ## values      : -2.959704, 3.233738  (min, max)

``` r
# Plot the raster
plot(study_raster2)

# Add in the monitoring stations
plot(study_locations, add = TRUE)
```

<img src="Chap6_Figs/unnamed-chunk-28-1.png" style="display: block; margin: auto auto auto 0;" />

Once satisfed, we save this layer to the **spatials directory** as an
RDS file, and add information about the file to the **spatials** table:

``` r
# Save the shapefile as an RDS file
save(study_raster2, file = 'spatials/study_raster.RDS')

# Prepare to add information to the database
add.raster <- data.frame(spatialID = 'study_raster',
                         type = 'raster',
                         class = 'RasterLayer',
                         filepath = 'spatials/study_raster.RDS',
                         description = "Middle Earth Raster")

# Add the record to the spatials database table 
RSQLite::dbWriteTable(conn = conx, name = 'spatials', value = add.raster,
                      row.names = FALSE, overwrite = FALSE,
                      append = TRUE, header = FALSE)
```

The **spatials** directory now contains three RDS files that store
spatial information about a monitoring program. Information about each
file is stored in the database table called **spatials**. Remember, the
**spatials** table merely *points* to the names of the spatial files
stored in the **spatials** directory – it does not store spatial data.
We will use these spatial layers in future chapters.

Finally, when we are finished with the database, we disconnect from it:

``` r
# Disconnect from the database
RSQLite::dbDisconnect(conx)
```

The Locations Table in Access
=============================

Locations can be found under the Access Navigation Form’s Locations tab,
and is a primary tab. Notice that the records are displayed in “form”
view, and that the image is diplaying the first of 50 locations that
come with the sample database.

<kbd>

<img src="Chap6_Figs/locations.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 6.2. The Locations table/form is a primary tab on the Access
> Navigation form.*

Also, notice the 6 secondary tabs associated with the “Locations” tab:
Spatials, Temporals, Equipment, Logs, Deployment, and Schedule.

The Spatials Table in Access
============================

The Spatials table can be accessed as a secondary tab under the
Locations tab. The default view for this form is “datasheet” view.
However, monitoring team members may choose to create more personalized
forms if desired.

<kbd>

<img src="Chap6_Figs/spatials.PNG" width="100%" style="display: block; margin: auto;" />

</kbd>

> *Figure 6.3. The Spatials table is nestled under the Location tab.
> This table does not store spatial information. Rather, it points to
> files that contain spatial data via a filepath.*

It is very easy to create many spatial objects (shapefiles or rasters)
that can be used in the analysis of monitoring data. The **spatials**
table provides a way document each layer, and futher can be used to
quickly load the objects to R if the file path is accurate.

Chapter Summary
===============

This chapter covered the **locations** table, which stores point
locations for a monitoring program. This table is critical, as it is
used by a variety of **AMMonitor** functions.

You also learned about the **spatials** table, which *points* to spatial
files that may be used in future analysis. In our examples, we created
spatial objects with the packages, **sp** and **raster**, and stored all
spatial objects as RDS files within a directory called **spatials**. We
will revisit these files in future chapters.

Chapter References
==================

1. Pebesma E, Bivand R. Sp: Classes and methods for spatial data
(version 1.3-1) \[Internet\]. Comprehensive R Archive Network; 2018.
Available: <https://cran.r-project.org/web/packages/sp/index.html>

2. Hijmans RJ. Raster: Geographic data analysis and modeling (version
2.8-4) \[Internet\]. Comprehensive R Archive Network; 2018. Available:
<https://cran.r-project.org/web/packages/raster/index.html>
