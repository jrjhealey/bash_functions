### GENERAL PURPOSE FUNCTIONS ###

# Extract any file extension
extract () {
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

#copy and go to dir
cpg (){
  if [ -d "$2" ];then
    cp $1 $2 && cd $2
  else
    cp $1 $2
  fi
}

#move and go to dir
mvg (){
  if [ -d "$2" ];then
    mv $1 $2 && cd $2
  else
    mv $1 $2
  fi
}

# Pretty print tabular files with unequal length cells
prettytab(){
column -t -s $'\t' -n "$1"
}

# History search
past (){
   echo "Searching the history for "$1"."
    history | grep $1
}


# Folder size
dush (){
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

# Function to return the local machine IP for scp etc.
client (){
echo $SSH_CLIENT | awk '{ print $1 }'
}

# Quick download
quickdl(){
for i in "$@" ; do
 scp -vrq -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null "$i" joehealey@$(client):~/Downloads
done
}

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
#!/bin/bash
splitfa(){
i=1;
while read line ; do
  if [ ${line:0:1} == ">" ] ; then
    header="$line"
    echo "$header" >> seq"${i}".fasta
  else
    seq="$line"
    echo "$seq" >> seq"${i}".fasta
    ((i++))
  fi
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
