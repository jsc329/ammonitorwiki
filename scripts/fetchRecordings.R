# fetchRecordings script

# Load AMMonitor
library(AMMonitor)

# Set up database connection
db.path <- paste0(getwd(), '/database/Chap20.sqlite')

# Connect to the database
conx <- dbConnect(drv = dbDriver('SQLite'), dbname = db.path)

# Turn the SQLite foreign constraints on
dbExecute(conn = conx, statement =
            "PRAGMA foreign_keys = ON;"
)

# Query to retrieve arguments from the scriptArgs table
results <- dbGetQuery(conn = conx, statement = "
            SELECT functionName, argumentName,
                   argumentValue, dataType, MAX(date)
            FROM scriptArgs
            GROUP BY functionName, argumentName")

# Extract each argument and set to R datatype
for (i in 1:nrow(results)) {

  # get the value
  value = results[i, 'argumentValue']

  # get datatype
  datatype <- results[i, 'dataType']

  # ensure the argument value is the correct datatype
  value <- switch(EXPR = datatype,
                        "character" = {as.character(value)},
                        "integer" = {as.integer(value)},
                        "numeric" = {as.numeric(value)},
                        "logical" = {as.logical(value)}
  )
  # assign the value to the argumentName
  assign(x = results[i,'argumentName'], value = value)
}


# Run dropboxMoveBatch
dropboxMoveBatch(db.path = db.path,
                 table = table,
                 dir.from = dir.from,
                 dir.to = dir.to,
                 token.path = token.path)

# Return a message
cat("Recordings have been moved from recording_drop to the recordings directory. Metadata have been logged into the recordings database table")
