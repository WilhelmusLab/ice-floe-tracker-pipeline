# Copy oscar configuration to your home directory
mkdir -p ~/.cylc/flow && cp oscar.global.cylc ~/.cylc/flow/global.cylc

cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-lopez-tiling -s 'PREPROCESSING="LopezTiling"'
cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-buckley-paper.conf -n beaufort-sea-buckley-paper-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/beaufort-sea-buckley-paper.conf -n beaufort-sea-buckley-paper-lopez-tiling -s 'PREPROCESSING="LopezTiling"'
cylc vip . --set-file example/beaufort-sea-buckley-paper.conf -n beaufort-sea-buckley-paper-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/fram-strait-april-may-2020.conf -n fram-strait-april-may-2020-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/fram-strait-april-may-2020.conf -n fram-strait-april-may-2020-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-lopez -s 'PREPROCESSING="Lopez"'
cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-buckley -s 'PREPROCESSING="Buckley"'

# Non-contiguous dates:
cylc vip . --set-file example/hudson-bay.conf -n hudson-bay --run-name=may-2006 --initial-cycle-point=2006-05-04 --final-cycle-point=2006-05-06
cylc vip . --set-file example/hudson-bay.conf -n hudson-bay --run-name=july-2008 --initial-cycle-point=2008-07-13 --final-cycle-point=2008-07-15