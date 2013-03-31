#!/bin/sh

# Based on Enrico's snippet for using pdflatex for building PDFs, except we're
# switching to pregenerating the docs for the SRPM so that we don't get
# different contents when we build on multiple build machines and architectures
# (timestamps and IDs change, and even some of the compressed content looks
# different).  The filename and checksum are used to verify that the PDF always
# matches the doc which was used to generate it, and we flag an error if that
# isn't the case.

create() {
	pushd "$1" > /dev/null
	touch "$2".ind
	pdflatex "$2"
	test ! -e "$2".idx || makeindex ${3:+-s "$3".ist} "$2".idx
	pdflatex "$2"
	pdflatex "$2"
	sum=`sha1sum "$2".tex | sed 's,[[:blank:]].*,,g'`
	sed -ri \
		-e 's|^/ID \[<.{32}> <.{32}>\]|/ID [<'"$1/$2"'> <'"$sum"'>]|g' \
		"$2".pdf
	popd > /dev/null
}

check() {
	pushd "$1" > /dev/null
	sum=`sha1sum "$2".tex | sed 's, .*,,g'`
	id=`sed -rn -e '/^\/ID \[<[^>]*> <[^>]*>\]/p' "$2".pdf`
	filename=`echo "$id" | sed -r 's|^.*\[<([^>]*)> <([^>]*)>\].*|\1|g'`
	checksum=`echo "$id" | sed -r 's|^.*\[<([^>]*)> <([^>]*)>\].*|\2|g'`
	echo $filename
	echo $checksum $sum
	popd > /dev/null
	test "$filename" = "$1/$2" && test "$checksum" = "$sum"
}

mode=$1
case $mode in
	create)
	while read subdir doc style ; do
		if ! create $subdir $doc $style ; then
			exit 1
		fi
	done
	;;
	check)
	while read subdir doc style ; do
		if ! check $subdir $doc $style ; then
			exit 1
		fi
	done
	;;
esac

exit 0
