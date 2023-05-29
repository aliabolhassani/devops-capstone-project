#!/bin/sh
cd $(dirname $0)

./mvnw clean package
ret=$?
if [ $ret -ne 0 ]; then
exit $ret
fi
rm -rf target

./mvnw spring-boot:build-image
ret=$?
if [ $ret -ne 0 ]; then
exit $ret
fi
rm -rf target

exit