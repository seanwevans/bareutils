; include/sysdefs.inc

%define SYS_READ        0
%define SYS_WRITE       1
%define SYS_OPEN        2
%define SYS_CLOSE       3
%define SYS_STAT        4
%define SYS_LSEEK       8

%define SYS_EXIT        60
%define SYS_UNAME       63

%define SYS_SYNC        74
%define SYS_TRUNCATE    76
%define SYS_FTRUNCATE   77
%define SYS_GETCWD      79

%define SYS_CHDIR       80
%define SYS_RMDIR       84
%define SYS_LINK        86
%define SYS_SYMLINK     88

%define SYS_CHOWN       92
%define SYS_UMASK       95
%define SYS_SYSINFO     99

%define SYS_GETUID      102
%define SYS_GETEUID     107

%define SYS_TIME        201
%define SYS_GETENV      211

%define SYS_UTIMENSAT   280

%define AT_FDCWD       -100     ; Used for relative paths with utimensat
%define SEEK_SET          0


%define STDIN_FILENO    0
%define STDOUT_FILENO   1
%define STDERR_FILENO   2

%define O_RDONLY        0
%define O_WRONLY        1
%define O_RDWR          2
%define O_CREAT         64
%define O_TRUNC         512
%define O_APPEND        1024

%define DEFAULT_MODE    0o644   ; rw-r--r--

%define UT_LINESIZE     32      ; Size of tty line field
%define UT_NAMESIZE     32      ; Size of username field
%define UT_HOSTSIZE     256     ; Size of hostname field

%define UTMP_SIZE       384

%define UT_TYPE_OFF     0       ; short   ut_type;       (Offset 0,   Size 2)
%define UT_PID_OFF      4       ; pid_t   ut_pid;        (Offset 4,   Size 4)
%define UT_LINE_OFF     8       ; char    ut_line[32];   (Offset 8,   Size 32)
%define UT_ID_OFF       40      ; char    ut_id[4];      (Offset 40,  Size 4)
%define UT_USER_OFF     44      ; char    ut_user[32];   (Offset 44,  Size 32)
%define UT_HOST_OFF     76      ; char    ut_host[256];  (Offset 76,  Size 256)
%define UT_EXIT_OFF     332     ; struct  exit_status;   (Offset 332, Size 4)
%define UT_SESSION_OFF  336     ; int32_t ut_session;    (Offset 336, Size 4)
%define UT_TV_OFF       340     ; struct  timeval32;     (Offset 340, Size 8)
%define UT_ADDR_OFF     348     ; int32_t ut_addr_v6[4]; (Offset 348, Size 16)

%define EMPTY           0       ; Record does not contain valid info
%define RUN_LVL         1       ; Change in system run-level
%define BOOT_TIME       2       ; Time of system boot
%define NEW_TIME        3       ; Time after system clock change
%define OLD_TIME        4       ; Time before system clock change
%define INIT_PROCESS    5       ; Process spawned by init
%define LOGIN_PROCESS   6       ; Session leader process for user login
%define USER_PROCESS    7       ; Normal user process
%define DEAD_PROCESS    8       ; Terminated process
%define ACCOUNTING      9

%define WHITESPACE_SPACE 32     ; ' '
%define WHITESPACE_TAB  9       ; '\t'
%define WHITESPACE_NL   10      ; '\n'

; exit(status)
%macro exit 1
    mov rax, SYS_EXIT
    mov rdi, %1                 ; exit code
    syscall
%endmacro

; write(fd, buf, len)
%macro write 3
    mov rax, SYS_WRITE
    mov rdi, %1                 ; file descriptor
    mov rsi, %2                 ; buffer address
    mov rdx, %3                 ; buffer length
    syscall
%endmacro
