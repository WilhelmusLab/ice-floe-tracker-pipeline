mkdir -p ~/.cylc/flow && cp global.cylc ~/.cylc/flow/.

cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-original -s 'PREPROCESSING="Original"'
cylc vip . --set-file example/iftpipeline-test-case.conf -n iftpipeline-test-case-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-original -s 'PREPROCESSING="Original"'
cylc vip . --set-file example/beaufort-sea-july.conf -n beaufort-sea-july-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-original -s 'PREPROCESSING="Original"'
cylc vip . --set-file example/beaufort-sea-march.conf -n beaufort-sea-march-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-original -s 'PREPROCESSING="Original"'
cylc vip . --set-file example/fram-strait-june.conf -n fram-strait-june-buckley -s 'PREPROCESSING="Buckley"'

cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-original -s 'PREPROCESSING="Original"'
cylc vip . --set-file example/ne-greenland.conf -n ne-greenland-buckley -s 'PREPROCESSING="Buckley"'