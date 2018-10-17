### GENERAL PURPOSE FUNCTIONS ###

# Alias to copy the remote STDOUT to the clients clipboard (OSX only)
alias copy="ssh joehealey@$(echo $SSH_CLIENT | awk '{ print $1 }') pbcopy"

# Function to return the local machine IP for scp etc.
client(){
echo $SSH_CLIENT | awk '{ print $1 }'
}

# Extract any file extension
Extract(){
   if [ -f $1 ] ; then
       case $1 in
           *.tar.bz2)   tar xvjf $1   ; echo "tar xvjf $1"  ;;
           *.tar.gz)    tar xvzf $1   ; echo "tar xvzf $1"  ;;
           *.bz2)       bunzip2 $1    ; echo "bunzip2 $1"   ;;
           *.rar)       unrar x $1    ; echo "unrar x $1"   ;;
           *.gz)        gunzip $1     ; echo "gunzip $1"    ;;
           *.tar)       tar xvf $1    ; echo "tar xvf $1"   ;;
           *.tbz2)      tar xvjf $1   ; echo "tar xvjf $1"  ;;
           *.tgz)       tar xvzf $1   ; echo "tar xvzf $1"  ;;
           *.zip)       unzip $1      ; echo "unzip $1"     ;;
           *.Z)         uncompress $1 ; echo "unzip $1"     ;;
           *.7z)        7z x $1       ; echo "7z x $1"      ;;
           *)           echo "don't know how to extract '$1'..." ;;
       esac
   else
       echo "'$1' is not a valid file!"
   fi
 }

# Run any arbitary command n times:
# Usage:   $ runx 5 command arg1 arg2 ...
runx(){
for ((n=0;n<$1;n++))
 do ${*:2}
done
}

# Double strip a bash variable (a bit like basename)
# Takes the file path off, and one 'layer' of extension
doublestrip(){
[[ $1 =~ ^.*/(.*)\. ]] && echo "${BASH_REMATCH[1]}"
}


# Colourise alternating output lines (useful for demarcating wrapped text)
colourit(){
while read line ; do
 echo -e "\e[1;34m$line"
 read line
 echo -e "\e[1;37m$line"
done
echo -en "\e[0m"
}

#copy and go to dir
cpg(){
  if [ -d "$2" ];then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

#move and go to dir
mvg(){
  if [ -d "$2" ];then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

# Pretty print tabular files with unequal length cells
prettytab(){
for i in "$@" ; do
 column -t -s $'\t' -n "$i"
done
}
# Use this function with find a lot, so make sure the function is available to subshells
export -f prettytab

# Latexify (format tables for easy copy-paste in to tex) (only designed for tabulated HHpred results!)
latexify(){
for i in "$@" ; do
 cat "$i" | cut -d$'\t' -f1,4,6- | \
 sed -r -e 's/\{/\\\{/g' -e 's/\}/\\\}/g' | \
 sed -r 's/>([[:upper:]]|[[:digit:]])*\_[[:upper:]]{,2}//g' | \
 sed -r 's/([0-9]*?\.?[0-9]*)?e-([0-9]{,4})/\\sn\{\1\}\{-\2}/g' | \
 sed -r 's/\\sn\{\}\{-\}/e-/g' | sed -r 's/([0-9]*\.[0-9]*)A/\1\\AA\{\}/g' | \
 sed -r 's/_/\\_/g'
done
}

# History search
past(){
   echo "Searching the history for "$1"."
    history | grep $1
}


# Folder size
dush(){
   echo "The size of "$1" is:"
   du -sh $1
}

# Print the first and last N lines of a file. $2 = N [Def = 10]
ends(){
if [ "$2" == "" ]; then
  head $1
  echo "-----"
  tail $1
elif [ "$2" != "" ] ; then
  head -"${2}" $1
  echo "-----"
  tail -"${2}" $1
else
 echo "Parameter not recognised"
fi
}

# Quickly sum a column of numbers in a text file
sum(){
awk '{ sum += $1 } END { print sum}'
}

# Make a simple backup of a file
backup(){
cp "$1" ./"${1}".bak
}

# Oneline git commit. $1 is the file, $2 is the commit message
commit(){
git add "$1" && git commit -m "$2" && git push
}

# Write out the history to a file
histdump(){
history > ~/histories/history_$(today).txt
}

# Search all the history files at once
fullpast(){
 echo "Searching all histories for "$1"."
    sort ~/histories/* | uniq -u | grep $1
}

# Print N random lines from a file. $1 is the file, $2 is N
randlines(){
for ((i=0;i<"$2";i++)) ; do
 perl -e 'srand; rand($.) < 1 && ($line = $_) while <>; print $line;' $1
done
}

# Quick download
quickdl(){
for i in "$@" ; do
 scp -vrq -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$i" joehealey@$(client):~/Downloads
done
}

# Collapse all whitespace in a file to a single tab per occurence 
ws2tab(){
for i in "$@" ; do
 perl -p -e 's/ +/\t/g' $i
done
}

alias tsview="cat $@ | column -s $'\t' -t | less -S"

### Bioinformatics-y Functions ###

# Print fasta headers in file $1
headers(){
 for i in "$@" ; do
  cat "$i" | grep ">"
 done
}

# Print all fasta sequence lengths (will print header followed by length) Works for multifa too
falens(){
for i in "$@" ; do
awk '/^>/ {if (seqlen){print seqlen}; print ;seqlen=0;next; } { seqlen += length($0)}END{print seqlen}' "$i"
done
}


# Remove duplicate fasta headers
dedupe(){
cat $1 | awk '!_[$0]++'
}

# Retain only first header line (concatenate a multifasta)

fastcat(){
cat $1 | sed -e '1!{/^>.*/d;}' | sed  ':a;N;$!ba;s/\n//2g' | sed  '1!s/.\{80\}/&\n/g'
}

# 'Genbank formatted' time
gentime (){
date +"%d-%b-%Y"
}

# Split a multifasta (gives the sequences arbitrary names though)
splitfa ()
{
    numseqs=$(grep -c ">" $1);
    numlines=$(wc -l < $1);
    if (( $numlines > $(( 2*$numseqs )) )); then
        echo "The fasta file needs to be linearised before this function will work.";
        return 1;
    fi;
    while read line; do
        if [ ${line:0:1} == ">" ]; then
            header="$line";
            filename=$(echo "${line#>}" | tr ' ' '_');
            echo "$header" >> "${filename}".fasta;
        else
            seq="$line";
            echo "$seq" >> "${header#>}".fasta;
        fi;
    done < $1
}

# Subset a fasta in to chunks of N sequences
# $1 is the file, $2 is the number of sequences per output file
subsetfa(){
awk -v n=$2 'BEGIN {n_seq=0;} /^>/ {if(n_seq%n==0){file=sprintf("myseq%d.fa",n_seq);} print >> file; n_seq++; next;} { print >> file; }' < $1
}

# Linearise a single or multifasta file to make it easier to work on
linearisefa(){
awk '/^>/ {printf("%s%s\t",(N>0?"\n":""),$0);N++;next;} {printf("%s",$0);} END {printf("\n");}' < $1
}

# Undo a linearisation operation (assume line width 80, specify with $2)
wrapfa(){
if [ -z ${2+80} ]; then
tr "\t" "\n" < $1 | fold -w $2
fi
}

# Generate a random fasta formatted sequence of length $1
# TODO: add some length customisability.
randomfa(){
str=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)
echo -e ">RandomSequence_${str}"
cat /dev/urandom | tr -dc 'ATCG' | fold | head -1
}


# Find matching substrings with a pattern in file
# $1 is pattern, $2 is file
find_subsequence(){
# An example pattern might be "ATG..AAG" for 2 random bases
egrep --color -zi "$1" $2
}

# Insert a fasta filename as the fasta header (single fasta only!)
filename2header(){
for i in "$@" ; do
 headerstring=$(echo "${i%.*}" | tr ' ' '_') # remove extension and any whitespace
 sed -r -i "s/^>.*/>$headerstring/g" "$i"
done
}

#Get the taxanames for all the leaves in a phylogenetic tree (in the order they appear left -> right
# (Requires ETE3 be installed in the right pythonpath
getleaves(){
 python3 -c 'import sys; from ete3 import Tree; t = Tree(sys.argv[1]);print(t.get_leaf_names());' "$1"
}

# Get the basic length of a string on the commandline (disregard quotes)
strlen(){
str="$1"
len="${#str}"
if [ "$len" == 0 ]; then
 echo "String missing or length 0."
else
 echo "$len"
fi
}

# Fastq to fasta
fq2fa(){
cat $1 | sed -n '1~4s/^@/>/p;2~4p'
}
