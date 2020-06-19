#!/bin/bash
#
# Description: This script allows the user to display resource information.
#
# Author: Daniel Huettner
#




# TABLE OF CONTENTS
# 1.	INITIALIZING GLOBAL VARIABLES
# 2.	MODULE FUNCTIONS
# 3.	PRINT FUNCTIONS
# 4.	INIT AND EXIT FUNCTIONS
# 5.	HANDLE MODULES
# 6.	HANDLE ERRORS
# 7.	HANDLE USER INPUT
# 8.	MAIN





#                       1. INITALIZING GLOBAL VARIABLES
#                       ===============================

# The set of module letters.  Modules are refered to by their letter (the
# character the user enters on the keyboard for that module).
# The letters are sorted in the order in which the modules appear on the
# terminal screen.
moduleLetters=( "h" "c" "m" "p" "u" "o" )


# Maps module letters to module names.
declare -A moduleName
moduleName["h"]="HEADER"
moduleName["c"]="CPU_GRAPH"
moduleName["m"]="MEM_GRAPH"
moduleName["p"]="PROCESSES"
moduleName["u"]="USERS"
moduleName["o"]="OPTIONS"


# Maps module names to module letters.
declare -A moduleLetter
moduleLetter["HEADER"]="h"
moduleLetter["CPU_GRAPH"]="c"
moduleLetter["MEM_GRAPH"]="m"
moduleLetter["PROCESSES"]="p"
moduleLetter["USERS"]="u"
moduleLetter["OPTIONS"]="o"


# Sets which modules are enabled and which are disabled.  A disabled module will
# not appear on screen.
declare -A moduleEnabled
moduleEnabled["h"]=false
moduleEnabled["c"]=false
moduleEnabled["m"]=false
moduleEnabled["p"]=false
moduleEnabled["u"]=false
moduleEnabled["o"]=true


# Stores the title for each module.
# This appears just above the module output on the screen, in bold, underlined
# text.
declare -A moduleTitle
moduleTitle["h"]=""
moduleTitle["c"]="CPU Usage Graph"
moduleTitle["m"]="Memory Usage Graph"
moduleTitle["p"]="Top 5 CPU-Intestive Processes"
moduleTitle["u"]="Who's Logged In"
moduleTitle["o"]="Options"


# Stores the current output for each module.
# This is updated every time the module's "Module Function" is called.
declare -A moduleOutput
moduleOutput["h"]=""
moduleOutput["c"]=""
moduleOutput["m"]=""
moduleOutput["p"]=""
moduleOutout["u"]=""
moduleOutput["o"]=""


# The set of error codes.  Each error message is identified by a unique
# integer (called its "Error Code").
# The errors are numbered in order of priority.  If two or more errors are
# triggered, then only the error with the lowest number will be printed.
errorCodes=( 1 2 )


# The set of error messages.
errorMessage[1]="ERROR (E001) - Not Enough Room On Screen"
errorMessage[2]="ERROR (E002) - Invalid Choice"


# If an error message is enabled, it will show up on screen.  If two or more
# error messages are enabled, then only the highest-priority (lowest numbered
# error code) will be displayed.
errorEnabled[1]=false
errorEnabled[2]=false


# The current screen contents.
# This is filled with the most up-to-date information, then printed to the
# terminal screen, then erased, with every main loop iteration.
# This way, everything is printed to the screen all at once (everything on
# the terminal screen is updated at the same time).
terminalOutput=""


# Used by the CPU_GRAPH module.
CPU_GRAPH_ROW[4]=''
CPU_GRAPH_ROW[3]=''
CPU_GRAPH_ROW[2]=''
CPU_GRAPH_ROW[1]=''
CPU_GRAPH_ROW[0]=''
for i in `seq 1 $(tput cols)`
do
	CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
	CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}' '
	CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}' '
	CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}' '
	CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}' '
done


# Used by the MEM_GRAPH module.
MEM_GRAPH_ROW[4]=''
MEM_GRAPH_ROW[3]=''
MEM_GRAPH_ROW[2]=''
MEM_GRAPH_ROW[1]=''
MEM_GRAPH_ROW[0]=''
for i in `seq 1 $(tput cols)`
do
	MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
	MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}' '
	MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}' '
	MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}' '
	MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}' '
done






#                             2. MODULE FUNCTIONS
#                             ===================

# The "Module Functions" generate/update the content for the given module.
#
# Every module has two parts:
#         Title        This appears just above the module output on the screen.
#         Output       This is the main content of the module.
#
# Each of the module functions, when called, will generate the output and save
# it to the moduleOutput["x"] array variable, where "x" is the module's
# menu letter.
#
# Each module function takes no parameters, and always has a return value of 0.


# The "Module Function" for the "OPTIONS" module.
function moduleFunction_OPTIONS () {
	moduleOutput[${moduleLetter["OPTIONS"]}]=\
'h)    Show/Hide Header
c)    Show/Hide CPU Usage Graph
m)    Show/Hide Memory Usage Graph
p)    Show/Hide Top 5 CPU-Intensive Processes
u)    Show/Hide Who is Logged In
o)    Show/Hide List of Options
q)    Quit'
	return 0
}


# The "Module Function" for the "HEADER" module.
function moduleFunction_HEADER () {
	timeOfDay="`date +%-l:%M%p`"
	cpuUsage="`ps -eo %cpu --no-headers | awk '
		   BEGIN { cpu=0; } { cpu+=$1; } END { print cpu; }'`"
	totalMemory="`grep '^MemTotal:' /proc/meminfo | sed 's/^[^0-9]*//g'`"
	freeMemory="`grep '^MemFree:' /proc/meminfo | sed 's/^[^0-9]*//g'`"
	moduleOutput[${moduleLetter["HEADER"]}]="Time: $timeOfDay | CPU: $cpuUsage% | Total Memory: $totalMemory | Free Memory: $freeMemory"
	return 0
}


# The "Module Function" for the "CPU_GRAPH" module.
function moduleFunction_CPU_GRAPH () {
	cpuUsage="`ps -eo %cpu --no-headers | awk '
		   BEGIN { cpu=0; } { cpu+=$1; } END { print cpu; }'`"
	cpuUsageOutOfFive=$[ $[ ${cpuUsage//\.[0-9]*/} / 20 ] + 1 ]

	# Removing the left-most character from each bar.
	CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]:1}
	CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]:1}
	CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]:1}
	CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]:1}
	CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]:1}

	# Adding either a '.' or a '*' character to each bar.

	# For the special case where CPU % is exactly zero.
	if [[ "$cpuUsage" = "0" ]]
	then
		CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
		CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}' '
		CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}' '
		CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}' '
		CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}' '
	else
	# For all other cases.
	case $cpuUsageOutOfFive in

		1)
			CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
			CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}' '
			CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}' '
			CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}' '
			CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}'*'
			;;

		2)
			CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
			CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}' '
			CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}' '
			CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}'*'
			CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}'*'
			;;

		3)
			CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
			CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}' '
			CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}'*'
			CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}'*'
			CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}'*'
			;;

		4)
			CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}' '
			CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}'*'
			CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}'*'
			CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}'*'
			CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}'*'
			;;

		5|6)
			CPU_GRAPH_ROW[4]=${CPU_GRAPH_ROW[4]}'*'
			CPU_GRAPH_ROW[3]=${CPU_GRAPH_ROW[3]}'*'
			CPU_GRAPH_ROW[2]=${CPU_GRAPH_ROW[2]}'*'
			CPU_GRAPH_ROW[1]=${CPU_GRAPH_ROW[1]}'*'
			CPU_GRAPH_ROW[0]=${CPU_GRAPH_ROW[0]}'*'
			;;
		
	esac
	fi
	
	moduleOutput[${moduleLetter["CPU_GRAPH"]}]=\
"`tput setaf 1`${CPU_GRAPH_ROW[4]}`tput sgr0`
`tput setaf 3`${CPU_GRAPH_ROW[3]}`tput sgr0`
`tput setaf 3`${CPU_GRAPH_ROW[2]}`tput sgr0`
`tput setaf 2`${CPU_GRAPH_ROW[1]}`tput sgr0`
`tput setaf 2`${CPU_GRAPH_ROW[0]}`tput sgr0`"
	return 0
}


# The "Module Function" for the "MEM_GRAPH" module.
function moduleFunction_MEM_GRAPH () {
	totalMemory="`grep '^MemTotal:' /proc/meminfo | sed -e 's/^[^0-9]*//g' -e 's/[^0-9]*$//g'`"
	freeMemory="`grep '^MemFree:' /proc/meminfo | sed -e 's/^[^0-9]*//g' -e 's/[kKbBmMgGtT ]*$//g'`"
	memUsage=$[ 100 - $[ $[ $freeMemory * 100] / $totalMemory ] ]
	memUsageOutOfFive=$[ $[ $memUsage / 20 ] + 1 ]

	# Removing the left-most character from each bar.
	MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]:1}
	MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]:1}
	MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]:1}
	MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]:1}
	MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]:1}

	# Adding either a '.' or a '*' character to each bar.

	# For the special case where MEM % is exactly zero.
	if [[ "$memUsage" = "0" ]]
	then
		MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
		MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}' '
		MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}' '
		MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}' '
		MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}' '
	else
	# For all other cases.
	case $memUsageOutOfFive in

		1)
			MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
			MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}' '
			MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}' '
			MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}' '
			MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}'*'
			;;

		2)
			MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
			MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}' '
			MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}' '
			MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}'*'
			MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}'*'
			;;

		3)
			MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
			MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}' '
			MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}'*'
			MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}'*'
			MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}'*'
			;;

		4)
			MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}' '
			MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}'*'
			MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}'*'
			MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}'*'
			MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}'*'
			;;

		5|6)
			MEM_GRAPH_ROW[4]=${MEM_GRAPH_ROW[4]}'*'
			MEM_GRAPH_ROW[3]=${MEM_GRAPH_ROW[3]}'*'
			MEM_GRAPH_ROW[2]=${MEM_GRAPH_ROW[2]}'*'
			MEM_GRAPH_ROW[1]=${MEM_GRAPH_ROW[1]}'*'
			MEM_GRAPH_ROW[0]=${MEM_GRAPH_ROW[0]}'*'
			;;
		
	esac
	fi
	
	moduleOutput[${moduleLetter["MEM_GRAPH"]}]=\
"`tput setaf 1`${MEM_GRAPH_ROW[4]}`tput sgr0`
`tput setaf 3`${MEM_GRAPH_ROW[3]}`tput sgr0`
`tput setaf 3`${MEM_GRAPH_ROW[2]}`tput sgr0`
`tput setaf 2`${MEM_GRAPH_ROW[1]}`tput sgr0`
`tput setaf 2`${MEM_GRAPH_ROW[0]}`tput sgr0`"
	return 0
}


# The "Module Function" for the "PROCESSES" module.
function moduleFunction_PROCESSES () {
	awkScript='
		BEGIN {
			printf "%-12s %-12s %-12s %-12s %-12s %-12s\n",
				"PROCESS ID", "USER", "STATE",
				"%CPU", "%MEMORY", "PROCESS NAME"
		}
		{
			if ($3 == "D")
				$3="sleeping"
			if ($3 == "R")
				$3="runnable"
			if ($3 == "S")
				$3="sleeping"
			if ($3 == "T")
				$3="stopped"
			if ($3 == "W")
				$3="paging"
			if ($3 == "X")
				$3="dead"
			if ($3 == "Z")
				$3="zombie"
			printf "%-12s %-12s %-12s %-12s %-12s %-12s\n",
				$1, $2, $3, $4, $5, $6
		}'

	moduleOutput[${moduleLetter["PROCESSES"]}]="$(
		ps -e -o pid:12,user:12,state:12,%cpu:12,%mem:12,comm:12 \
		   --sort=-%cpu --no-headers \
		| head -5 \
		| awk "$awkScript")"

	return 0
}


# The "Module Function" for the "USERS" module.
function moduleFunction_USERS () {
	moduleOutput[${moduleLetter["USERS"]}]="`users | sed 's/ /\n/g' | uniq`"
}






#                              3. PRINT FUNCTIONS
#                              ==================

# These functions are used to print text to the terminal screen.
#
# NOTE: All Print Functions, other than refreshScreen, store the output in
# a buffer (the terminalOutput string).  When the refreshScreen function is
# called, then the contents of the buffer are printed to the screen all at once.
# This way, every line of text on the screen is updated at the same instant.
#
#
# SCREEN REFRESHING:
#
# Every time the screen is refreshed, instead of clearing the screen, the new
# text is printed overtop of the old text.  This eliminates the flicker that is
# generally seen whenever the screen is cleared instead of overwritten with each
# refresh.
#
# The "Print Functions" are designed for overwriting previous text left on the
# screen from the last refresh.  Specifically, these functions will make
# extensive use of the 'tput' command to position the cursor wherever text
# needs to be printed, as well as erase lingering text that was not completely
# overwritten.
#
# NOTE: text wrapping is disabled in this script. If a line of text is longer
# than the length (i.e. number of columns) of the terminal screen, it will be
# trimmed to fit.



# Prints a title to the terminal screen, bold, underlined text.
#
# NOTE: if the title's length (number of characters) exceeds the number of
# columns in the terminal screen, it will be trimmed to fit.
#
# Parameters:
#      #1  The title string.
#
# Return Value:
#       0	Success
function printTitle () {
	# Enable bold text.
	printString "`tput bold`" false
	# Enable underlined text.
	printString "`tput smul`" false
	# Print the title.
	printString "$1" true
	# Reset the text to normal (i.e. no bold, no underline).
	printString "`tput sgr0`" false
	# Return success (0) error code.
	return 0
}


# Prints an error message to the terminal screen.
#
# Errors are printed in bold text with a red background.
#
# Parameters:
#	#1	The error message string.
# Return Value:
#       0       Success
function printError () {
	# Enters bold text mode
	printString "`tput bold`" false
	# Changes the background colour to red.
	printString "`tput setb 4`" false
	# Print the error string.
	printString "$1" false
	# Undo all the fancy text options.
	printString "`tput sgr0`" false
	# Return success (0) error code.
        return 0
}


# Clears to the end of the current line on the screen, then advances the cursor
# to the first column of the following line.
#
# Parameters:
#       None.
#
# Return Value:
#       0       Success
function printBlankLine () {
	printString "`tput el`" true
	return 0
}


# Prints the specified string to the terminal.
# 
# NOTE: each line who's length (number of characters) exceeds the number of
# columns in the terminal screen will be trimmed to fit.
#
# Parameters:
#       #1	The string is read from the first parameter.
#	#2	A boolean value to indicate whether or not to add a newline
#		to the end of the string (true means add the newline).
# Return Value:
#       0       Success
function printString () {
	if $2	# Specifies whether or not to add a newline to the end.
	then
		terminalOutput=$"$terminalOutput$1"$'\x0A'
	else
		terminalOutput=$"$terminalOutput$1"
	fi
	# Return a success (0) error code.
	return 0
}


# Prints all the buffered output to the terminal screen.
#
# Each line in the output is trimmed to fit in the terminal screen (to prevent
# word wrap).
#
# Parameters:
#	None.
#
# Return Value:
#	0	Success
function refreshScreen () {
	# Print the output buffer to the terminal.  Append the `tput el`
	# terminal code to the end of each line of the output.  This will
	# instuct the terminal to clear any text left on that line that was
	# not overwritten.
	echo -n "$terminalOutput" | sed "s/\$/`tput el`/g"
	# Clear the current output buffer.
	terminalOutput=""
}





#                          4. INIT AND EXIT FUNCTIONS
#                          ==========================


# Initializes the script.
#
# Parameters:
#	None.
#
# Return Value:
#	0	Success
function initScript  () {
	# Disables unicode text, which can drastically improve performance.
	LC_ALL_OLD=$LC_ALL
	export LC_ALL=C
	# Disables word wrap if a line of text is too long to fit on the screen.
	tput rmam
	# The following command will instruct the terminal to hide user input
	# from the keyboard.  By default, when the user presses a key on the
	# keyboard, it will show up on screen.  This prevents that from
	# happening
	stty -echo
	# The following command will make the cursor invisible.
	tput civis
	# The following command will clear the screen.
	tput clear
}


# Exits the script.
#
# Parameters:
#	None.
#
# Return Value:
#       The script will return 0.
function exitScript  () {
	# Enable word wrap.
	tput smam
	# Reset text to normal (i.e. no bold).
	tput sgr0
	# Re-enable visibility of the text the user types in.  This was disabled
	# when the script was first run.
	stty echo
	# Re-enable visibility of the cursor.  This was disabled when the script
	# was first run.
	tput cnorm
	# Restore Unicode text processing.
	export LC_ALL=$LC_ALL_OLD
	# Position cursor on last line of the terminal screen.
	tput cup $[ `tput lines` - 1 ] 0
	echo
	# Exit the script with a success (i.e. "0") error code.
        exit 0
}




#                              5. HANDLE MODULES
#                              =================


# Updates all modules, and displays the enabled modules.
#
# If a module cannot be displayed because there is not enough room left on the
# terminal screen, then the error message with error code 1 is enabled.
#
# Parameters:
#	None.
#
# Return Value:
#	0	Success
function handleModules () {
	#
	# UPDATE THE MODULES
	#

	# Call the Module Function to update the module's output.  This will
	# update the output of all modules, including the disabled ones.
	for name in ${moduleName[@]}
	do
		eval "moduleFunction_"$name
	done



	#
	# PRINT THE MODULES
	#

	# Place the cursor at the top left of the terminal screen.
	printString "`tput cup 0 0`" false

	# Calculate the number of lines available to print on the terminal
	# screen. This does not include the last line, which is reserved for
	# error messages.
	numLinesLeft=$[ `tput lines` - 1 ]

	# This will be set true again if one or more modules cannot be printed
	# because there's not enough room left on the terminal screen.
	errorEnabled[1]=false

	# Print the output of the enabled modules.	
	for letter in ${moduleLetters[@]}
	do
		if ${moduleEnabled[$letter]}
		then
			# Print the module.
			printModule $letter
		fi
	done

	# Clears the rest of the screen, except for the last line, which is
	# handled by the printError function.
	while [[ $numLinesLeft != 0 ]]
	do
		printBlankLine
		numLinesLeft=$[ $numLinesLeft - 1 ]
	done



	#
	# END
	#

	# Return success (0) error code.
	return 0
}


# (Helper function for handleModules).
#
# Prints the title and output of a module to the terminal screen.
#
# This function will print out the module as follows:
# 	title
#	output
#	1 blank line
#
# NOTE: the title will be printed as bold, underlined text.
#
# NOTE: each line who's length (number of characters) exceeds the number of
# columns in the terminal screen will be trimmed to fit.
#
# NOTE: If there's not enough lines remaining on the terminal screen, then the
# module will not be printed.  In that case, then the error message with
# error code 1 is enabled.  Also, the return value in this case is 1.
#
# NOTE: if the title string is empty, then no title is printed.
# NOTE: if the output string is empty, then NOTHING is printed.
#
# Parameters:
#       #1	The module's letter is taken as the only parameter
#
# Return Value:
#	0	Success
#	1	Unable to print because there was not enough room on the screen.
#	2	There was nothing to print!  The output was empty.
function printModule () {
	#
	# CALCULATE NUMBER OF LINES REQUIRED TO PRINT MODULE
	#

	# Lines required for title.
	if [[ -z "${moduleTitle[$1]}" ]]
	then
		# Title string is empty.
		numLinesTitle=0
	else
		# Title string is non-empty.
		numLinesTitle=`echo "${moduleTitle[$1]}" | wc -l`
	fi

	# Lines required for output.
	if [[ -z "${moduleOutput[$1]}" ]]
	then
		# Output string is empty.
		numLinesOutput=0
	else
		# Output string is non-empty.
		numLinesOutput=`echo "${moduleOutput[$1]}" | wc -l`
	fi

	# Total lines required (extra line added after the output, hence the +1)
	numLinesTotal=$[ $numLinesTitle + $numLinesOutput + 1 ]


	#
	# CHECK FOR ERRORS
	#

	# ERROR CHECK : Unable to print because there is not enough room left on
	#		the terminal screen.
	if [[ $numLinesLeft -lt $numLinesTotal ]]
	then
		# Enable the error message.
		errorEnabled[1]=true
		# Return error code 1.
		return 1
	fi

	# ERROR CHECK : Unable to print because the output of the module is
	#		empty.
	if [[ $numLinesOutput -eq 0 ]]
	then
		# Return error code 2.
		return 2
	fi


	#
	# PRINT THE MODULE
	#

	# Print the title (only if it is non-empty).
	if [[ $numLinesTitle -gt 0 ]]
	then
		printTitle "${moduleTitle[$1]}"
	fi

	# Print the output.
	printString "${moduleOutput[$1]}" true

	# Print a blank line
	printBlankLine

	# Update the numLinesLeft variable.
	numLinesLeft=$[ $numLinesLeft - $numLinesTotal ]



	#
	# END
	#

	# Return a success (i.e. "0") error code.
	return 0
}





#                               6. HANDLE ERRORS
#                               ================

# Prints the highest-priority enabled error message (if any) to the last line
# on the terminal screen.
#
# Parameters:
#	None.
#
# Return Value:
#	0	Success
function handleErrors () {
	# Places the cursor on the last line of the terminal screen.
	printString "`tput cup $[ $(tput lines) - 1 ] 0`" false

	# Set to false if there is at least one error message enabled.
	noErrors=true

	# Prints the highest-priority enabled error (if any).
	for errorCode in ${errorCodes[@]}
	do
		if ${errorEnabled[$errorCode]}
		then
			printError "${errorMessage[$errorCode]}"
			noErrors=false
			break
		fi
	done

	# If there weren't any errors enabled, then erase the error line.
	if $noErrors
	then
		printString `tput el` false
	fi
}





#                            7. HANDLE USER INPUT
#                            ====================

# Reads in the user input, and executes the appropriate action.
#
# If the user does not enter anything within the time limit, then the function
# returns without doing anything.
#
# Parameters:
#	None.
#
# Return Value:
#	0	Success
function handleUserInput () {
	# Read The user input.
	read -n1 -t1 -s option

	# The valid module letters.
	moduleLettersRegex="${moduleLetters[@]}"
	moduleLettersRegex="[${moduleLettersRegex// /}]"

	# Execute the appropriate action.
	case "$option" in

		# The input matches a module letter.
		$moduleLettersRegex)
			errorEnabled[2]=false
			toggleModule $option
			;;

		# The input is 'q'.
		q)
			errorEnabled[2]=false
			exitScript
			;;

		# The input is empty.
		"")
			;;

		# The input is invalid.
		*)
			errorEnabled[2]=true
			;;

	esac

	# Return a success (0) error code.
	return 0
}


# (Helper function for handleUserInput).
#
# Toggles (i.e. enables or disables) the module who's corresponding letter
# (from the menu) is in the menuChoice variable.
#
# Parameters:
#	#1	The module letter is read from the first parameter.
#
# Return Value
#	0	Success
function toggleModule () {
	if ${moduleEnabled[$1]}
	then
		moduleEnabled[$1]=false
	else
		moduleEnabled[$1]=true
	fi
	return 0
}





#                                   8. MAIN
#                                   =======

# Initialize the script.
initScript

# The main Loop.
while true
do
	# Updates the modules and prints the enabled ones to the screen.
	handleModules

	# Prints the highest-priority error to the screen.
	handleErrors

	# Refresh the terminal screen (print out all the new output generated
	# by the above two commands).
	refreshScreen

	# Read and process the user input.
	handleUserInput
done




# Not the correct way to exit
exit 1
