<div><img src="ammonitor-footer.png" width="1000px" align="center"></div>

-   [Chapter Introduction](#chapter-introduction)
-   [“CRUD” operations in R](#crud-operations-in-r)
    -   [Reading records](#reading-records)
    -   [Creating records](#creating-records)
    -   [Updating records](#updating-records)
    -   [Deleting records](#deleting-records)
-   [“CRUD” operations in Access](#crud-operations-in-access)
-   [Chapter Summary](#chapter-summary)

Chapter Introduction
====================

The **people** table in an **AMMonitor** SQLite database tracks
information about all members involved in a monitoring program. In
addition to providing a convenient contact book, this table is used to
identify project members who annotate species presence or absence in an
audio or image file, or who deploy monitoring equipment at a monitoring
station.

For this chapter, we will use `dbCreateSample()` to create a database
called “Chap3.sqlite”, which will be stored in a folder (directory)
called **database** within the **AMMonitor** main directory, which
should be your working directory in R. Recall that `dbCreateSample()`
generates all tables of an **AMMonitor** database, and then
pre-populates sample data into tables specified by the user. For
demonstration purposes in this chapter, we will only pre-populate the
**people** table.

``` r
# Create a sample database for this chapter
dbCreateSample(db.name = "Chap3.sqlite", 
               file.path = paste0(getwd(),"/database"), 
               tables =  "people")
```

    ## An AMMonitor database has been created with the name Chap3.sqlite which consists of the following tables:

    ## accounts, annotations, assessments, classifications, deployment, equipment, library, listItems, lists, locations, logs, objectives, people, photos, priorities, prioritization, recordings, schedule, scores, scriptArgs, scripts, soundscape, spatials, species, sqlite_sequence, templates, temporals

    ## 
    ## Sample data have been generated for the following tables: 
    ## people

Next, we connect to the database with RSQLite’s `dbConnect()` function,
where we must identify the SQLite driver in the ‘drv’ argument:

``` r
# Establish the database file path as db.path
db.path <- paste0(getwd(), '/database/Chap3.sqlite')

# Connect to the database
conx <- RSQLite::dbConnect(drv = dbDriver('SQLite'), dbname = db.path)
```

Finally, we send a SQL statement that will enforce foreign key
constraints:

``` r
# Turn the SQLite foreign constraints on
RSQLite::dbExecute(conn = conx, statement = "PRAGMA foreign_keys = ON;")
```

    ## [1] 0

The `dbTables()` function provides the table schema for any table in the
database, such as primary keys, column names, the type of information
stored, and default values. We point to the database by inputting the
**db.path** object to the ‘db.path’ argument, and indicate “people” as
the table of interest in the ‘table’ argument:

``` r
# Look at information about the people table
dbTables(db.path = db.path, table = "people")
```

    ## $people
    ##   cid        name         type notnull dflt_value pk comment
    ## 1   0    personID VARCHAR(255)       1         NA  1        
    ## 2   1   firstName VARCHAR(255)       0         NA  0        
    ## 3   2    lastName VARCHAR(255)       0         NA  0        
    ## 4   3 projectRole VARCHAR(255)       0         NA  0        
    ## 5   4       email VARCHAR(255)       0         NA  0        
    ## 6   5       phone VARCHAR(255)       0         NA  0

`dbTables()` returns a list of table schemas, in this case, a list of 1,
which contains a data.frame of information about the **people** table.
The *cid* column indicates the column (field) number; *name* indicates
the column name; *type* conveys the data type for that column as
contained within the underlying SQLite database. Thus, the **people**
table consists of six fields (columns): “personID”, “firstName”,
“lastName”, “projectRole”, “email”, and “phone”. Each field stores
VARCHAR (variable character length) data, storing up to 255 characters.
In R, VARCHAR data are of class “character”. The *notnull* column
indicates whether an entry is required for that field; if 1, an entry is
required (in the people table, for example, no new record can be created
without adding a personID, though remaining fields may be left blank). A
column’s *dflt\_value* specifies the default value is used for that
field (NA indicates no default value).

Lastly, *pk* indicates whether the field is a primary key. In the
**people** table, *personID* is the primary key. This is the single,
unique identifier that points to a specific person in the **people**
table, and with very few exceptions should **never be changed or
deleted** or the integrity of the data in other tables may be
compromised.

“CRUD” operations in R
======================

Reading records
---------------

To view the contents of an existing table using R, we have a few
options. If the table is relatively small, we can use the RSQLite
function `dbReadTable()` to read the entire table into R’s memory, again
specifying our **conx** object in the ‘conn’ argument, and “people” as
the table of interest in the ‘name’ argument.

``` r
# Read the entire table and store as get.people
get.people <- RSQLite::dbReadTable(conn = conx, name = "people")

# Look at the entire table (printed as a tibble)
get.people
```

    ##   personID firstName lastName          projectRole                    email        phone
    ## 1 bbaggins     Bilbo  Baggins  Lead Ring Monitor I ringmaster2001@shire.net         none
    ## 2 fbaggins     Frodo  Baggins Lead Ring Monitor II       fbaggins@shire.net 888-ONE-RING

The *personID* is the primary key of this table, and uniquely identifies
each record in the **people** table. Duplicate *personID*s are not
allowed. Above, we have chosen the convention of combining the first
initial with the last name with no separating spaces.

Notice that once this information object is read from SQLite into R, it
can be treated as a typical R data.frame. We can use the `class()`
function to confirm that the **get.people** object is a data.frame.

``` r
class(get.people)
```

    ## [1] "data.frame"

As an alternative to the `dbReadTable()` function, we can query certain
fields and records of the table using SQL syntax. This is a useful
approach if we only need specific types of information from the
**people** table, or if we suspect the table is quite large and do not
want to read all of it into memory within R. The **people** table is not
likely to become especially large, but the option to query tables
directly using SQL syntax will be useful when we encounter larger tables
later on.

We use the `dbGetQuery()` function to query database tables and return
records of interest. Yet again, we specify our **conx** object in the
‘conn’ argument. In the ‘statement’ argument, we provide a character
string that passes the SQL instructions for querying the database. The
online [**SQLite Tutorial**](http://www.sqlitetutorial.net/) provides
help for how these SQL character string queries should be structured,
and we will step through a few examples below.

To select the entire table, we use the SQL command “SELECT \* FROM
people”, where the ‘\*’ in our character string indicates that we want
to return all fields (columns) of the table. The simple statement below
gives no identifying information about which records (rows) should be
returned, so all records will be selected and returned:

``` r
# Use * to select all rows and columns of the people table
RSQLite::dbGetQuery(conn = conx, 
                    statement = "SELECT * 
                                 FROM people")
```

    ##   personID firstName lastName          projectRole                    email        phone
    ## 1 bbaggins     Bilbo  Baggins  Lead Ring Monitor I ringmaster2001@shire.net         none
    ## 2 fbaggins     Frodo  Baggins Lead Ring Monitor II       fbaggins@shire.net 888-ONE-RING

To only look at the first record, we can add the statement “LIMIT 1” to
the end of our character string (if we had many records and only wanted
to see the first 12, we could use, e.g., “LIMIT 12”):

``` r
# Only look at the first  record
RSQLite::dbGetQuery(conn = conx, 
                    statement = "SELECT * 
                                 FROM people 
                                 LIMIT 1")
```

    ##   personID firstName lastName         projectRole                    email phone
    ## 1 bbaggins     Bilbo  Baggins Lead Ring Monitor I ringmaster2001@shire.net  none

If we only want to return information on a particular column, we can
name that column specifically in the SQLite character string instead of
using the ‘\*’ symbol. Below, we demonstrate using the *firstName*
column:

``` r
# Only look at the firstName column
RSQLite::dbGetQuery(conn = conx, 
                    statement = "SELECT firstName 
                                 FROM people")
```

    ##   firstName
    ## 1     Bilbo
    ## 2     Frodo

More complex queries can be constructed depending on the information
needed. Next, we query all columns, but introduce a **where** statement
to indicate that we only want records where the first name is equal to
‘Frodo’. We have to add single quotes around ‘Frodo’ because it is a
character.

``` r
# Only select records with "Frodo" in the firstName column
RSQLite::dbGetQuery(conn = conx, 
                    statement = "SELECT * 
                                 FROM people 
                                 WHERE firstName = 'Frodo' ") 
```

    ##   personID firstName lastName          projectRole              email        phone
    ## 1 fbaggins     Frodo  Baggins Lead Ring Monitor II fbaggins@shire.net 888-ONE-RING

As with `dbReadTable()`, results returned from `dbGetQuery()` can be
stored as a data.frame for further manipulation in R.

Note that both the `dbReadTable()` and `dbGetQuery()` functions require
you be be actively connected to the database via a **conx** object in
order to return table information. Depending on your workflow, it may be
more useful to avoid creating a **conx** object in order to avert
database conflicts among multiple users. In this case, you may opt to
use the **AMMonitor** `qry()` function, which only requires a
**db.path** object input to the ‘db.path’ argument, and either a table
name input to the ‘table’ argument (if you wish to read an entire table
into memory), or a SQLite statement input to the ‘statement’ argument.
`qry()` acts as a wrapper function for either `dbReadTable()` or
`dbGetQuery()`, and takes care of connecting and disconnecting from the
database for you. It returns the results as a data.table in R. The below
code shows how you can use `qry()` to read in an entire table, or to use
a SQLite statement to select records of interest:

``` r
# Read in the entire people table
qry(db.path = db.path, 
    table = 'people')
```

    ##    personID firstName lastName          projectRole                    email        phone
    ## 1: bbaggins     Bilbo  Baggins  Lead Ring Monitor I ringmaster2001@shire.net         none
    ## 2: fbaggins     Frodo  Baggins Lead Ring Monitor II       fbaggins@shire.net 888-ONE-RING

``` r
# Only select records with "Frodo" in the firstName column
qry(db.path = db.path, 
    table = NULL,
    statement = "SELECT * 
                 FROM people 
                 WHERE firstName = 'Frodo' ") 
```

    ##    personID firstName lastName          projectRole              email        phone
    ## 1: fbaggins     Frodo  Baggins Lead Ring Monitor II fbaggins@shire.net 888-ONE-RING

The `qry()` approach is essentially the same as `dbReadTable()` or
`dbGetQuery()`, except that it allows you to input a **db.path** object
rather than a **conx** object.

Creating records
----------------

The simplest way to add records to the database is to generate a
data.frame of records, and then use the `dbWriteTable()` function to
insert them. We begin by creating two records, ensuring that all column
names in the data.frame exactly match the field names in the database
itself. We take care to ensure that the data types in the data.frame
match those expected by the database.

``` r
# Create a dataframe of records to add
add.people <- data.frame(personID = c('gandalf', 
                                      'saruman'),
                         firstName = c('Gandalf', 
                                       'Saruman'),
                         lastName = c('The Grey', 
                                      'The White'),
                         projectRole = c('Wizard Consultant', 
                                         'Power Seeker'),
                         email = c('gandalf@middle.earth',
                                   'saruman@isengard.net'),
                         phone = c(NA, 
                                   NA))
```

The *personID* is the primary key; it is required and should not
duplicate keys that already exist in the table. The *firstName*,
*lastName*, *projectRole*, *email*, and *phone* columns track basic
information about each person involved in the monitoring project, though
entries for these fields are not required.

Once we are satisfied with the contents and formatting of our table of
new records, we can insert it to the **people** table using the RSQLite
function `dbWriteTable()`. In the ‘conn’ argument we specify the
**conx** object, and use ‘name’ to specify the **people** table. The
‘value’ we bind is the **add.people** object. We set ‘row.name’ and
‘header’ to FALSE because our data.frame does not contain row names or a
header. We set ‘append’ to TRUE in order to add new data to an existing
table, and we set ‘overwrite’ to FALSE to indicate that it will not
overwrite existing records.

``` r
# Bind new records to the people table of the database
RSQLite::dbWriteTable(conn = conx, name = 'people', value = add.people,
             row.names = FALSE, overwrite = FALSE,
             append = TRUE, header = FALSE)

# Check database to confirm new records were added
RSQLite::dbGetQuery(conn = conx, 
                    statement = 'SELECT * FROM people')
```

    ##   personID firstName  lastName          projectRole                    email        phone
    ## 1 bbaggins     Bilbo   Baggins  Lead Ring Monitor I ringmaster2001@shire.net         none
    ## 2 fbaggins     Frodo   Baggins Lead Ring Monitor II       fbaggins@shire.net 888-ONE-RING
    ## 3  gandalf   Gandalf  The Grey    Wizard Consultant     gandalf@middle.earth         <NA>
    ## 4  saruman   Saruman The White         Power Seeker     saruman@isengard.net         <NA>

Alternatively, one can add a new record by constructing an entire
character string of SQL syntax and passing it to the RSQLite function
`dbExecute()`, using an INSERT statement to identify the table fields
and values. Notice that single quotes are required around all of the
VARCHAR (character) data values in the statement. Below, we have added
tabs and spaces to our statement to make the contents easier to read,
but R does not do this automatically, and any long character statements
can become cumbersome as a result, making this option more difficult to
use:

``` r
# Insert a new record using SQLite syntax 
RSQLite::dbExecute(conn = conx, 
                   statement = 
               "INSERT INTO people (
                   personID, 
                   firstName, 
                   lastName, 
                   projectRole, 
                   email, 
                   phone
                  )
                VALUES (
                  'gimli',
                  'Gimli',
                  'Son of Gloin',
                  'Support Staff', 
                  'gimli@dwarves.org',
                  '1-800-AND-MYAX'
                  )"
          
) # close the dbExecute statement
```

    ## [1] 1

`dbExecute()` returns a “1” to indicate that one record has been added
to the table. We use `dbGetQuery()` to check on all fields and records
of the table, confirming that our new records have been added:

``` r
# Check on the table
RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM people")
```

    ##   personID firstName     lastName          projectRole                    email          phone
    ## 1 bbaggins     Bilbo      Baggins  Lead Ring Monitor I ringmaster2001@shire.net           none
    ## 2 fbaggins     Frodo      Baggins Lead Ring Monitor II       fbaggins@shire.net   888-ONE-RING
    ## 3  gandalf   Gandalf     The Grey    Wizard Consultant     gandalf@middle.earth           <NA>
    ## 4  saruman   Saruman    The White         Power Seeker     saruman@isengard.net           <NA>
    ## 5    gimli     Gimli Son of Gloin        Support Staff        gimli@dwarves.org 1-800-AND-MYAX

Updating records
----------------

To modify information in an existing record, we use an UPDATE statement
in `dbExecute()`, ensuring that any VARCHAR or TEXT values are enclosed
in single quotes. Below, we pass a SQL statement that finds all records
where *lastName* is equal to Baggins, and modify those phone numbers to
become 1-800-shire:

``` r
# Update cell phones for anyone with last name baggins:
RSQLite::dbExecute(conn = conx, 
                   statement = "UPDATE people 
                                SET phone = '1-800-shire'
                                WHERE LastName = 'Baggins' ")
```

    ## [1] 2

This action returns a “2” to convey that 2 records were updated.

Again, we can use `dbGetQuery()` to check that our Baggins phone number
updates were successful:

``` r
# Check on the table
RSQLite::dbGetQuery(conn = conx, 
                    statement = "SELECT * 
                                 FROM people 
                                 WHERE lastName = 'Baggins'")
```

    ##   personID firstName lastName          projectRole                    email       phone
    ## 1 bbaggins     Bilbo  Baggins  Lead Ring Monitor I ringmaster2001@shire.net 1-800-shire
    ## 2 fbaggins     Frodo  Baggins Lead Ring Monitor II       fbaggins@shire.net 1-800-shire

Deleting records
----------------

To delete specific records from a table, we again invoke the
`dbExecute()` function, this time with a DELETE statement. Below, we
combine the DELETE statement with a WHERE statement to delete any
records containing ‘Gimli’ in the *firstName* column:

``` r
# Remove the Gimli record
RSQLite::dbExecute(conn = conx, 
                   statement = "DELETE FROM people 
                                WHERE firstName = 'Gimli' ")
```

    ## [1] 1

Another call to `dbGetQuery()` confirms that our deletion was
successful:

``` r
# Check on the table
RSQLite::dbGetQuery(conn = conx, statement = "SELECT * FROM people")
```

    ##   personID firstName  lastName          projectRole                    email       phone
    ## 1 bbaggins     Bilbo   Baggins  Lead Ring Monitor I ringmaster2001@shire.net 1-800-shire
    ## 2 fbaggins     Frodo   Baggins Lead Ring Monitor II       fbaggins@shire.net 1-800-shire
    ## 3  gandalf   Gandalf  The Grey    Wizard Consultant     gandalf@middle.earth        <NA>
    ## 4  saruman   Saruman The White         Power Seeker     saruman@isengard.net        <NA>

**Note that records should be deleted with extreme care.** As mentioned
in Chapter 2, an **AMMonitor** database does not invoke “cascade
delete;” when a record is deleted, entries in other tables that use the
primary key of the deleted record will not be automatically be deleted.
In this case, if we delete “Gimli” from the **people** table, we may
produce dangling records that reference Gimli in other tables. For
example, if Gimli spent time annotating recordings for presence or
absence of focal species \[See Chapter 14\], his *personID* would be
contained in the **annotations** table, but his corresponding personal
information would no longer be present in the **people** table.

Finally, we disconnect from the database when finished with
modifications:

``` r
# Disconnect from the database
RSQLite::dbDisconnect(conx)
```

“CRUD” operations in Access
===========================

Figure 3.1 shows the **AMMonitor** Access front end, which is a
Navigation Form in Access (a form containing many forms). The top of the
form consists of primary tabs (3.1a), including Program Mgt, Objectives,
Species, Locations, Recordings, and Photos. When a primary tab is
selected (e.g., the Program Mgt tab has been selected), the left menu
displays a set of secondary tabs (3.1b). Thus, “People” fall under the
realm of Program Mgt (3.1c).

<kbd>

<img src="Chap3_Figs/NavigationForm.PNG" width="100%" style="display: block; margin: auto auto auto 0;" />

</kbd>

> \*Figure 3.1. The People form is located under the Program Mgt primary
> tab.

This table’s fields are displayed in a form-like view above, and can
alternatively be displayed in a spreadsheet view. As previously
mentioned, the **people** table consists of six columns (fields), and a
single record is displayed in the form (3.1d). Now let’s take a look at
CRUD operations in Access:

-   **C**reate a new record by pressing the sun icon button (3.1f), and
    fill in the fields.
-   **R**ead a record is simply viewing an existing record, such as the
    one displayed in Figure 3.1. Toward the bottom of the form, we can
    advance from record to record using the arrow buttons (3.1e).
-   **U**pdate a record by simply changing an entry in the form. Then,
    move from the current record by pressing either the back or forward
    arrows (Figure 3.1e).
-   **D**eleting records in the **AMMonitor** database should be done
    with caution, for the reasons outlined above. Thus, we have not
    included a ‘delete’ button in the Access form. However, if you must
    delete records, you can highlight the records of interest in the
    linked tables, and then press Delete on your keyboard. **Always
    remember: if you delete a record that is used downstream in other
    tables, it is up to you to determine how you will maintain the
    integrity of downstream data!** Your monitoring program should
    establish standards for how the team will handle deletions.

Chapter Summary
===============

This chapter was a brief introduction to the **people** table in an
**AMMonitor** SQLite database. People play a vital role in the
monitoring effort, deploying equipment, annotating files, creating
templates, and more. You may interact with this table via R by using the
`dbReadTable()`, `dbWriteTable()`, `dbGetQuery()`, or `dbExecute()`
functions. We also introduced a few SQL commands that can be used to
create, read, update, or delete records from a database table. Results
from these functions are stored in R as data.frames, where you can
manipulate the data further as you wish. You may also interact with this
table via the Access front end.
