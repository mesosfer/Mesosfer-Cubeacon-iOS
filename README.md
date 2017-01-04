# Mesosfer - Beacon Module #

Beacon module is one of Mesosfer module that has specific feature to manage beacon activities.

## Storyline ##
This module used for showing a “story” when beacons are detected or in range e.g. museum, merchant shop, etc. Y0u can manage what “story” that need to show to the end users when detected beacon e.g. some alert text or notification, displaying an image campaign, playing a video campaign or maybe open some website. You can also choose when the “story” must displayed based on beacon’s event :
* **Enter**, triggered when user entering region of a beacon
* **Exit**, triggered when user exiting region of a beacon
* **Immediate**, triggered when user range approximately <1 meter from beacon
* **Near**, triggered when user range approximately within 1-3 meters from beacon
* **Far**, triggered when user range approximately >3 meters from beacon

Besides, you can select what days to show when “story” was triggered. By using a storyline, you can manage multiple beacon’s “story”.

## Presence ##
This module can be used to tracking any check-in and check-out data e.g. employee attendance, student presence, etc.

## Notification ##
This module is the simple version of storyline, it can only manage a beacon for each notification e.g. show a greeting when user entering shop.

## Microlocation ##
This module can be used for track indoor location using a mapped beacon in an area.

### Reference Links ##
* Learn about how to use Mesosfer-Module at [wiki page](https://github.com/mesosfer/Mesosfer-Cubeacon-iOS/wiki)
* Download the [complete code](https://github.com/mesosfer/Mesosfer-Cubeacon-iOS/archive/master.zip)

### LICENSE ###
    Copyright (c) 2016, Mesosfer.
    All rights reserved.

    This source code is licensed under the BSD-style license found in the
    LICENSE file in the root directory of this source tree.
