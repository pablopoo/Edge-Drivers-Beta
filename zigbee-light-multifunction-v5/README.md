## (NEW RELEASE) Version 5.0 of the Edge Driver Zigbee Light Multifunction Mc

link to community thread:

https://community.smartthings.com/t/new-release-beta-edge-driver-zigbee-light-multifunction-mc/234387/33?u=mariano_colmenarejo

 ## Changes and Improvements:

1- I have merged in this Driver the three existing similar Drivers:

- Zigbee Light Multifunction Mc

- Zigbee Light Multifunction and Tr-Time

- Zigbee Light Multifunction Group Mc

2- Transition Time functions for Off-On-Off, Level, Color temperature and Color changes are adjustable from preferences with times from 0 sec to 10 sec.

-Not all zigbee light bulbs work with the Transition Time Argument. If it does not work properly or you want to use the default values of the hardware and platform, you just have to put the values = 0 sec all settings or the ones you need.

3- The configuration functions to add and delete Groups, cluster 0x0004, it works like this:

- When we add one or more devices to a group, we can send commands directly to all the devices in the same group with a remote control, which supports this function , without having to go through the Hub.

- I’ve added a custom capability, shown at the end, which shows the group numbers that are added to this device. You can also delete all the groups added from this capability.
 
- To add new groups:

- Open settings, preferences and in the Add Group options type the group number to add

- Inserting Value = 0 reads all Added Groups and displays them in the custom capability and event history.

- To Delete groups individually:

- Open settings, preferences and in the Options Remove Group number type the group number to remove.

- inserting value = 0 remove all groups


# (NEW RELEASE) Version 3.0 of the Edge Driver Zigbee Light Multifunction Mc

## Improvements and bug fixes:

My Thanks to @milandjurovic71 for test the driver with his bulbs.

As a request, @eric182 , the Continuous Color Change function has been added:

-Has a Custom Capability to turn the function Active and Inactive.

-Has a Custom Capability to modify the Timer between 1 and 20 sec for Color Changes

-Has a Custom Capability to select Color Change Mode

-Continuous Mode : The initial color is adjusted randomly and changes continuously with the rhythm of the timer chosen between 1 and 20 Sec.

-Random Mode : Color is adjusted randomly continuously with each timer interval

-All Modes : Both modes run randomly for a time between 50 sec to 300 sec each random cycle. Color change with random timer between 1 and 3 seconds.


## (NEW RELEASE) Version 2.0 of the Edge Driver Zigbee Light Multifunction Mc

## Improvements and bug fixes:

At the request of @milandjurovic71, preferences have been added for Minimum and Maximum Level settings of the Circadian Lighting function. In this way they are independent of the Llevel settings for progressive ON

The code has been corrected to prevent the “ Active " selections of the Progressive ON-OFF and Circadian Lighting functions from being reset to " Inactive " when a Reboot Hub or Driver update happens.


## (New RELEASE) New Edge Drive Zigbee Light Multifunction Mc:

- This Driver has all the functions of the Zigbee Level ColorTemp Bulb Mc driver, which it replaces and will not be updated any more.

## Added Color Control Capability with profiles for RGB and RGBW with 2700k-6500k Color temperature.

Thanks to the suggestion and collaboration to do the tests for @milandjurovic71


-All three capabilities are accessible for use with routines and scenes
Color change timer and color change mode can be modified dynamically.


## Works with lights, led strips with profiles:

Switch & Level
Switch, Level & ColorTemperature
Switch, Level, RGB, RGBW, RGBCCT, CCT
Could work with zigbee single dimmers, but not tested

## Included Devices :

See fingerprints.yml file
