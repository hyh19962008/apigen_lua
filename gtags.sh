#!/bin/bash
## generate file_list for building gtags symbols
OUTPUT=gtags_list
rm -rf $OUTPUT
find ControlPlane/include/*.h >> $OUTPUT
find ControlPlane/include/y_api/*.h >> $OUTPUT
find ControlPlane/y_api/*.c >> $OUTPUT
find ControlPlane/y_api/src/*.c >> $OUTPUT
find ForwardingPlane/include/*.h >> $OUTPUT
find ForwardingPlane/include/be/*.h >> $OUTPUT
find ForwardingPlane/include/fp/*.h >> $OUTPUT

gtags -i -f gtags_list
