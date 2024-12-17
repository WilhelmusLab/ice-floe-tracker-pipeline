# Copy oscar configuration to your home directory
mkdir -p ~/.cylc/flow && cp oscar.global.cylc ~/.cylc/flow/global.cylc

cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/fram-strait-april-may-2020.conf -n fram-strait-april-may-2020-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/fram-strait-april-may-2020.conf -n fram-strait-april-may-2020-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-buckley -s 'PREPROCESSING="Buckley"'