Nodediag provides an extensible
[TAP](http://testanything.org/wiki/index.php/Main_Page TAP)
framework for executing node diagnostic checks at system startup.

Tests installed in `/etc/nodediag.d/` are run in parallel by the `nodediag`
command:
```
Checking cpucount:                                          [  OK  ]
Checking ecc:                                               [  OK  ]
Checking infiniband:                                        [NOTRUN]
Checking ethernet:                                          [  OK  ]
Checking mpt2sas:                                           [  OK  ]
Checking mptsas:                                            [  OK  ]
Checking network:                                           [  OK  ]
Checking sbe:                                               [  OK  ]
Checking swap:                                              [  OK  ]
Checking dmi:                                               [  OK  ]
Checking tw:                                                [NOTRUN]
Checking tapwrap:                                           [ FAIL ]
Checking hdparm:                                            [  OK  ]
```

Expected results are configured in `/etc/sysconfig/nodediag`
or `/etc/sysconfig/nodediag.d/`_testname_.

Tests can be listed with `nodediag -l`:
```
cpucount:        Check number of CPU cores
dmi:             Check dmi table values
ecc:             Check EDAC ECC type
ethernet:        Check ethernet config
hdparm:          Check hard drive read performance
infiniband:      Check infiniband config
mpt2sas:         Check mpt2sas cards
mptsas:          Check mptsas cards
network:         Check network config
sbe:             Check Single Bit Memory Error Count
swap:            Check for expected amount of swap
tapwrap:         Run non-TAP tests: nvidia 
tw:              Check 3ware cards
```

An init script is provided so diagnostics can be run at startup, with
the (verbose) results redirected to `/var/log/nodediag`.
Alternatively `nodediag` can be run as part of a cluster bringup
procedure, determining whether a node is fit to start cluster services;
or as part of a resource manager epilog between batch jobs to detect
emerging problems.
