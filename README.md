`RDBMS Sampler`
==============

A Ruby command line utility for extracting a sample of records from a relational 
database system (such as MySQL) while *maintaining referential integrity* in the sample. 

Need e.g. 1000 rows from each of your production tables, but feel the pain of making 
sure to include dependent rows, their dependents and so on, ad infinitum?

Look no further. This tiny utility will take care that referential dependencies are
fulfilled by recursively expanding the row sample with unfilled dependencies until
the sample is referentially consistent.

COMMANDS
--------

    help                 Display global or [command] help documentation.
    sample               Extract a sample from the given connection

OPTIONS
-------

    --adapter NAME
        ActiveRecord adapter to use

    --database NAME
        Name of database to sample

    --username USER
        Username for connection

    --password PASSWORD
        Password for connection

    --encoding ENCODING
        Encoding for connection

    --host HOST
        Host name or IP for connection

    --socket PATH
        Socket for connection

    --rows NUM
        Number of rows to sample per table

    --log PATH
        Log queries to PATH

GLOBAL OPTIONS
--------------

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs

USAGE
-----

    rdbms_sampler --database SOME_DB --username MY_USER --password MY_PASS --rows 100 > sample.sql

CAVEATS
-------

You will probably need to disable foreign key check *during import*, since inserts in 
the output are not ordered with respect to referential integrity.
