
Ever found yourself wanting a modest amount of fresh rows from a production database
for development purposes, but put back by the need to maintain referential integrity
in the extracted data sample?

This data sampling utility will take care that referential dependencies are
fulfilled by recursively expanding the sample with unfilled dependencies until
the sample is referentially consistent.

  COMMANDS:

    help                 Display global or [command] help documentation.
    sample               Extract a sample from the given connection

  OPTIONS:

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

    --socket PATH
        Socket for connection

    --rows NUM
        Number of rows to sample per table

    --log PATH
        Log queries to PATH

  GLOBAL OPTIONS:

    -h, --help
        Display help documentation

    -v, --version
        Display version information

    -t, --trace
        Display backtrace when an error occurs
