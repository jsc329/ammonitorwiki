# fetchRecordings script

# Load AMMonitor
library(AMMonitor)

# Set up database connection
db.path <- paste0(getwd(), '/database/AMMonitor_demo.sqlite')

# Connect to the database
conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)

# Turn the SQLite foreign constraints on
dbExecute(conn = conx, statement =
            "PRAGMA foreign_keys = ON;"
)

# Retrieve the temporals, but use data in the scriptArgs table to populate the function.





# Return a message

