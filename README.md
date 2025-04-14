# 🧱 bareutils

A reimplementation of `coreutils` in x86_64 assembly using direct syscalls only — no libc or dependencies.


## 🛠 Build Instructions

```bash
make
```


## Catalog
- ✅ `arch` Prints machine hardware name
- ⭕️ `b2sum` Computes and checks BLAKE2b message digest
- ⭕️ `base32` Encodes or decodes Base32, and prints result to standard output
- ⭕️ `base64` Encodes or decodes Base64, and prints result to standard output
- ✅ `basename` Removes the path prefix from a given pathname
- ⭕️ `basenc` Encodes or decodes various encodings and prints result to standard output
- ⭕️ `cat` Concatenates and prints files on the standard output
- ⭕️ `chcon` Changes file security context
- ⭕️ `chgrp` Changes file group ownership
- ⭕️ `chmod` Changes the permissions of a file or directory
- ✅ `chown` Changes file ownership
- ⭕️ `chroot` Changes the root directory
- ⭕️ `cksum` Checksums (IEEE Ethernet CRC-32) and count the bytes in a file
- ⭕️ `comm` Compares two sorted files line by line
- ⭕️ `cp` Copy files/directories
- ⭕️ `csplit` Splits a file into sections determined by context lines
- ⭕️ `cut` Removes sections from each line of files
- ⭕️ `date` Display or set date and time
- ⭕️ `dd` Copies and converts a file
- ⭕️ `df` Shows disk free space on file systems
- ⭕️ `dircolors` Set up color for ls
- ✅ `dirname` Strips non-directory suffix from file name
- ⭕️ `du` Shows disk usage on file systems
- ✅ `echo` Displays a specified line of text
- ⭕️ `env` Run a program in a modified environment
- ⭕️ `expand` Converts tabs to spaces
- ⭕️ `expr` Evaluates expressions
- ⭕️ `factor` Factors numbers
- ✅ `false` Does nothing, but exits unsuccessfully
- ⭕️ `fmt` Simple optimal text formatter
- ⭕️ `fold` Wraps each input line to fit in specified width
- ⭕️ `groups` Prints the groups of which the user is a member
- ⭕️ `head` Output the beginning of files
- ⭕️ `hostid` Prints the numeric identifier for the current host
- ✅ `id` Prints real or effective UID and GID
- ⭕️ `install` Copies files and set attributes
- ⭕️ `join` Joins lines of two files on a common field
- ⭕️ `link` Creates a link to a file
- ⭕️ `ln` Creates a link to a file
- ✅ `logname` Print the user's login name
- ⭕️ `ls` List directory contents with formatting
- ⭕️ `md5sum` Computes and checks MD5 message digest
- ⭕️ `mkdir` Creates directories
- ⭕️ `mkfifo` Makes named pipes (FIFOs)
- ⭕️ `mknod` Makes block or character special files
- ⭕️ `mktemp` Creates a temporary file or directory
- ⭕️ `mv` Moves files or rename files
- ⭕️ `nice` Modifies scheduling priority
- ⭕️ `nl` Numbers lines of files
- ⭕️ `nohup` Allows a command to continue running after logging out
- ✅ `nproc` Queries the number of (active) processors
- ⭕️ `numfmt` Reformat numbers
- ⭕️ `od` Dumps files in octal and other formats
- ⭕️ `paste` Merges lines of files
- ⭕️ `pathchk` Checks whether file names are valid or portable
- ⭕️ `pinky` A lightweight version of finger
- ⭕️ `pr` Converts text files for printing
- ✅ `printenv` Prints environment variables
- ⭕️ `printf` Formats and prints data
- ⭕️ `ptx` Produces a permuted index of file contents
- ✅ `pwd` Prints the current working directory
- ⭕️ `readlink` Displays value of a symbolic link
- ⭕️ `realpath` Returns the resolved absolute or relative path for a file
- ⭕️ `rm` Removes files/directories
- ⭕️ `rmdir` Removes empty directories
- ⭕️ `runcon` Run command with specified security context
- ⭕️ `seq` Prints a sequence of numbers
- ⭕️ `sha1sum` Computes and checks SHA-1/SHA-2 message digests
- ⭕️ `sha224sum` Computes and checks SHA-1/SHA-2 message digests
- ⭕️ `sha256sum` Computes and checks SHA-1/SHA-2 message digests
- ⭕️ `sha384sum` Computes and checks SHA-1/SHA-2 message digests
- ⭕️ `sha512sum` Computes and checks SHA-1/SHA-2 message digests
- ⭕️ `shred` Overwrites a file to hide its contents, and optionally deletes it
- ⭕️ `shuf` generates random permutations
- ✅ `sleep` Delays for a specified amount of time
- ⭕️ `sort` sorts lines of text files
- ⭕️ `split` Splits a file into pieces
- ⭕️ `stat` Returns data about an inode
- ⭕️ `stdbuf` Controls buffering for commands that use stdio
- ⭕️ `stty` Changes and prints terminal line settings
- ⭕️ `sum` Checksums and counts the blocks in a file
- ⭕️ `sync` Flushes file system buffers
- ⭕️ `tac` Concatenates and prints files in reverse order line by line
- ⭕️ `tail` Output the end of files
- ✅ `tee` Sends output to multiple files
- ⭕️ `test` Evaluates an expression
- ⭕️ `timeout` Runs a command with a time limit
- ⭕️ `touch` Changes file timestamps; creates file
- ⭕️ `tr` Translates or deletes characters
- ✅ `true` Does nothing, but exits successfully
- ⭕️ `truncate` Shrink or extend the size of a file to the specified size
- ⭕️ `tsort` Performs a topological sort
- ✅ `tty` Prints terminal name
- ✅ `uname` Prints system information
- ⭕️ `unexpand` Converts spaces to tabs
- ✅ `uniq` Removes duplicate lines from a sorted file
- ⭕️ `unlink` Removes the specified file using the unlink function
- ⭕️ `uptime` Tells how long the system has been running
- ⭕️ `users` Prints the user names of users currently logged into the current host
- ✅ `wc` Prints the number of bytes, words, and lines in files
- ✅ `who` Prints a list of all users currently logged in
- ✅ `whoami` Prints the effective userid
- ✅ `yes` Prints a string repeatedly
