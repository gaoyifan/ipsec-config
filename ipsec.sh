#!/usr/bin/env bash

SRC=$1
DST=$2

BASEDIR=$(dirname "$0")
cd $BASEDIR/ipsec.key.d

if [[ -e ${SRC}-${DST} ]]; then
	KEY_FILE=${SRC}-${DST}
elif [[ -e ${DST}-${SRC} ]]; then
	KEY_FILE=${DST}-${SRC}
else
	KEY_FILE=${SRC}-${DST}
	echo KEY1=0x$(dd if=/dev/urandom count=32 bs=1 2> /dev/null| xxd -p -c 64) >> $KEY_FILE
	echo KEY2=0x$(dd if=/dev/urandom count=32 bs=1 2> /dev/null| xxd -p -c 64) >> $KEY_FILE
	echo ID=0x$(dd if=/dev/urandom count=4 bs=1 2> /dev/null| xxd -p -c 8) >> $KEY_FILE
fi

source $KEY_FILE

if [[ $MODE == start ]]; then
	ip xfrm state add src $SRC dst $DST proto esp spi $ID reqid $ID mode transport auth sha256 $KEY1 enc aes $KEY2
	ip xfrm state add src $DST dst $SRC proto esp spi $ID reqid $ID mode transport auth sha256 $KEY1 enc aes $KEY2
	ip xfrm policy add src $SRC dst $DST dir out tmpl src $SRC dst $DST proto esp reqid $ID mode transport
	ip xfrm policy add src $DST dst $SRC dir in tmpl src $DST dst $SRC proto esp reqid $ID mode transport
elif [[ $MODE == stop ]]; then
	ip xfrm state delete src $SRC dst $DST proto esp spi $ID
	ip xfrm state delete src $DST dst $SRC proto esp spi $ID
	ip xfrm policy delete src $SRC dst $DST dir out
	ip xfrm policy delete src $DST dst $SRC dir in
fi
