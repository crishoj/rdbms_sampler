RDBMS Sampler
=============

Command line utility for extracting a sample (subset of all records) from a relational 
database system (such as MySQL) while *maintaining the referential integrity* of the sample. 

Description
-----------

Need e.g. 1000 rows from each of your production tables, but feel the pain of making 
sure to include dependent rows, their dependents and so on, ad infinitum?

Look no further. This tiny utility will take care that referential dependencies are
fulfilled by recursively expanding the row sample with unfilled dependencies until
the sample is referentially consistent.

Installation
------------

Install with `gem install rdbms_sampler`.
    
Alternatively, clone the repository and install dependencies with `bundle install`. 
Then execute with `bundle exec rdbms_sampler ...`.

Commands
--------

    help        Display global or [command] help documentation.
    sample      Extract a sample from the given connection

Options
-------

    --adapter NAME
        ActiveRecord adapter to use

    --databases NAMES
        Comma-separated list of databases to sample

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

Global Options
--------------

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs

Usage
-----

    rdbms_sampler --databases DB1,DB2 --username USER --password PASS --rows 100 > sample.sql



CAVEATS
-------

Only single-column foreign keys are currently handled. 

Additionally, due to a bug in the current implementation, if a referenced column 
is named anything but `id`, referenced rows might get included multiple times.

You will probably need to disable foreign key check *during import*, since inserts in 
the output are not ordered with respect to referential integrity.
