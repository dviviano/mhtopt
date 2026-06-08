* _clean_log.do -- Strip command echo from a Stata log file
*
* Usage:
*   global clean_log_path "path/to/logfile.txt"
*   run "`root'/stata/_clean_log.do"
*
* Reads the log at $clean_log_path, removes echoed commands and log
* header/footer, collapses blank lines, and overwrites the file
* with a clean version containing only output and display text.

if "$clean_log_path" == "" {
    display as error "_clean_log.do: global clean_log_path must be set before calling"
    exit 198
}

local logpath "$clean_log_path"

tempname fh_in fh_out
tempfile cleanlog

file open `fh_in'  using "`logpath'", read text
file open `fh_out' using `cleanlog',  write text replace

local prev_blank = 0

file read `fh_in' line
while r(eof) == 0 {
    local skip = 0

    * --- Command echo: ". command" ---
    if substr(`"`macval(line)'"', 1, 2) == ". " local skip = 1

    * --- Continuation lines: "> ..." ---
    if substr(`"`macval(line)'"', 1, 2) == "> " local skip = 1

    * --- Numbered loop lines: " N. command" with varying indentation ---
    * Require the period to be followed by a space or end-of-line so that
    * output rows beginning with a decimal (e.g. "  0.23  ...") are NOT stripped.
    if regexm(`"`macval(line)'"', "^ +[0-9]+\.( |$)") local skip = 1

    * --- Lines that are only dashes (log separators) ---
    if regexm(`"`macval(line)'"', "^-+$") local skip = 1

    * --- Log header/footer metadata ---
    if regexm(`"`macval(line)'"', "^      name:")  local skip = 1
    if regexm(`"`macval(line)'"', "^       log:")  local skip = 1
    if regexm(`"`macval(line)'"', "^  log type:")  local skip = 1
    if regexm(`"`macval(line)'"', "^ opened on:")  local skip = 1
    if regexm(`"`macval(line)'"', "^ closed on:")  local skip = 1

    if !`skip' {
        local is_blank = (`"`macval(line)'"' == "")
        * Collapse consecutive blank lines into one
        if `is_blank' & `prev_blank' {
            * skip duplicate blank
        }
        else {
            file write `fh_out' `"`macval(line)'"' _n
        }
        local prev_blank = `is_blank'
    }

    file read `fh_in' line
}

file close `fh_in'
file close `fh_out'

copy `cleanlog' "`logpath'", replace

* Clean up global
macro drop clean_log_path
