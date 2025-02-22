--- Smartthings library load ---
local capabilities = require "st.capabilities"
local ZigbeeDriver = require "st.zigbee"
local defaults = require "st.zigbee.defaults"
local zcl_clusters = require "st.zigbee.zcl.clusters"
local OnOff = zcl_clusters.OnOff
local Groups = zcl_clusters.Groups


---- Load handlers written in random.lua
local driver_handler = {}

--- Device running and update preferences variables
local device_running = {}
local oldPreferenceValue ={}
local newParameterValue ={}

-- Random tables variables
local random_Step = {}
local random_totalStep = {}
local random_timer = {}

-- Custom Capability Randon On Off
local random_On_Off = capabilities["legendabsolute60149.randomOnOff2"]
local random_Next_Step = capabilities["legendabsolute60149.randomNextStep2"]
local energy_Reset = capabilities["legendabsolute60149.energyReset1"]
local get_Groups = capabilities["legendabsolute60149.getGroups"]

----- do_init device tables create for dimming variables ----
function driver_handler.do_init (self, device)
  local device_exist = "no"
  for id, value in pairs(device_running) do
   --print("id >>>>, device_runniung >>>>>, device >>>>>",id, device_running[id], device)
   if device_running[id] == device then
    device_exist = "si"
   end
  end
 ---- If is new device initialize table values
 if device_exist == "no" then
  device_running[device]= device
  oldPreferenceValue[device] = "-"
  newParameterValue[device] = "-"
  random_Step[device] = 1
  random_totalStep[device] =2
  random_timer[device] = math.random(10, 20)

  -- send zigbee event if random on-of inactive
  print("<<<< random_state >>>>>",device:get_field("random_state"))
  if device:get_field("random_state") == "Inactive"  or device:get_field("random_state") == nil then
   device:emit_event(random_On_Off.randomOnOff("Inactive"))
   device:emit_event(random_Next_Step.randomNext("Inactive"))
   device:set_field("random_state", "Inactive", {persist = true})
  end
  ----- print device init values for debug------
  for id, value in pairs(device_running) do
   print("device_running[id]=",device_running[id])
   print("device_running, random_Step=",device_running[id],random_Step[id])
   print("device_running, random_totalStep=",device_running[id],random_totalStep[id])
   print("device_running, random_timer=",device_running[id],random_timer[id])
  end
 end
  --restart random on-off if active
  print("random_state >>>>>",device:get_field("random_state"))
  if device:get_field("random_state") ~= "Inactive" then  
    driver_handler.random_on_off_handler(self,device,"Active")
  end
  
  -- initialice total energy and restart timer if is ON 
  if device:get_field("power_time_ini") == nil then device:set_field("power_time_ini", os.time(), {persist = false}) end
  print("Last_energy_Total >>>>>",device:get_latest_state("main", capabilities.energyMeter.ID, capabilities.energyMeter.energy.NAME))
  print("energy_Total >>>>>",device:get_field("energy_Total"))
  print("energy_Total_persist >>>>>",device:get_field("energy_Total_persist"))
  print("power_meter_timer >>>>>>>",device:get_field("power_meter_timer"))

  if device:get_field("energy_Total_persist") == nil then
    local energy_Total = device:get_latest_state("main", capabilities.energyMeter.ID, capabilities.energyMeter.energy.NAME)
    if energy_Total == nil then energy_Total = 0 end
    device:set_field("energy_Total", energy_Total, {persist = false}) 
  else
    device:set_field("energy_Total", device:get_field("energy_Total_persist"), {persist = false})
  end
  if device:get_field("powerTimer_Changed") == nil then device:set_field("powerTimer_Changed", "No", {persist = false}) end
  if device:get_field("date_reset") == nil then 
    local date_reset = "Last Reset Date: "..os.date("%m/%d/%Y").." (m/d/y)"
    device:set_field("date_reset", date_reset, {persist = true})
  end
  device:emit_event(energy_Reset.energyReset(device:get_field("date_reset")))
  if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on" and device.preferences.loadPower > 0 then
    --device:set_field("power_meter_timer", "OFF", {persist = true})
     -- send zigbee event
    device:send(OnOff.server.commands.On(device))
  end
  device:set_field("power_meter_timer", "OFF", {persist = true})

end

---- do_removed device procedure: delete all device data
function driver_handler.do_removed(self,device)
  for id, value in pairs(device_running) do
    if device_running[id] == device then
    device_running[device] =nil
    oldPreferenceValue[device] = nil
    newParameterValue[device] = nil
    random_Step[device] = nil
    random_totalStep[device] = nil
    random_timer[device] = nil
   end
  end
  
  -----print tables of devices no removed from driver ------
  for id, value in pairs(device_running) do
    print("device_running[id]",device_running[id])
    print("device_running, random_Step=",device_running[id],random_Step[id])
    print("device_running, random_totalStep=",device_running[id],random_totalStep[id])
    print("device_running, random_timer=",device_running[id],random_timer[id])
 end
end

--- Update preferences after infoChanged recived---
function driver_handler.do_Preferences (self, device)
  for id, value in pairs(device.preferences) do
    print("device.preferences[infoChanged]=", device.preferences[id])
    oldPreferenceValue[device] = device:get_field(id)
    --print("oldPreferenceValue ", oldPreferenceValue[device])
    newParameterValue[device] = device.preferences[id]
    --print("newParameterValue ", newParameterValue[device])
    if oldPreferenceValue[device] ~= newParameterValue[device] then
      device:set_field(id, newParameterValue[device], {persist = true})
      print("<< Preference changed: name, old, new >>", id, oldPreferenceValue[device], newParameterValue[device])
 
      --- Groups code preference value changed
    if id == "groupAdd" then
      if device.preferences[id] > 0 then
       print("Add Groups >>>>>>>>>>>>>>>>>")
       local data = device.preferences[id]
       device:send(Groups.server.commands.AddGroup(device, data, "Group"..tostring(data)))
       device:send(Groups.server.commands.GetGroupMembership(device, {}))
      else
       device:send(Groups.server.commands.GetGroupMembership(device, {}))
      end
     end
 
     if id == "groupRemove" then
      print("Remove Groups >>>>>>>>>>>>>>>>>")
      if device.preferences[id] > 0 then
       device:send(Groups.server.commands.RemoveGroup(device, device.preferences[id]))
      else
       device:send(Groups.server.commands.RemoveAllGroups(device, {}))
      end
      device:send(Groups.server.commands.GetGroupMembership(device, {}))
     end

      ---- Timers Cancel ------
      --for timer in pairs(device.thread.timers) do
       --print("<<<<< Cancelando timer >>>>>")
       --device:set_field("power_meter_timer", "OFF", {persist = true})
       --device.thread:cancel_timer(timer)
      --end 

      ------ Change profile & Icon
      if id == "changeProfile" then
       if newParameterValue[device] == "Switch" then
        device:try_update_metadata({profile = "single-switch"})
       elseif newParameterValue[device] == "Plug" then
        device:try_update_metadata({profile = "single-switch-plug"})
       elseif newParameterValue[device] == "Light" then
        device:try_update_metadata({profile = "single-switch-light"})
       elseif newParameterValue[device] == "Vent" then
        device:try_update_metadata({profile = "switch-vent"})
       elseif newParameterValue[device] == "Camera" then
        device:try_update_metadata({profile = "switch-camera"})
       elseif newParameterValue[device] == "Humidifier" then
        device:try_update_metadata({profile = "switch-humidifier"})
       elseif newParameterValue[device] == "Air" then
        device:try_update_metadata({profile = "switch-air"})
       elseif newParameterValue[device] == "Tv" then
        device:try_update_metadata({profile = "switch-tv"})
       elseif newParameterValue[device] == "Oven" then
        device:try_update_metadata({profile = "switch-oven"})
       elseif newParameterValue[device] == "Refrigerator" then
        device:try_update_metadata({profile = "switch-refrigerator"})
       elseif newParameterValue[device] == "Washer" then
        device:try_update_metadata({profile = "switch-washer"})
       end   
      --- Preference power timer changed
      elseif id == "powerTimer" then
       if device:get_field("power_meter_timer") == "ON" then 
        device:set_field("powerTimer_Changed", "Yes", {persist = false})
       end 
    end  
    end
  end
  --print manufacturer, model and leng of the strings
  local manufacturer = device:get_manufacturer()
  local model = device:get_model()
  local manufacturer_len = string.len(manufacturer)
  local model_len = string.len(model)

  print("Device ID", device)
  print("Manufacturer >>>", manufacturer, "Manufacturer_Len >>>",manufacturer_len)
  print("Model >>>", model,"Model_len >>>",model_len)
end

----------------------------------------------------------
-- Save energy comsuption ------------------------
local function save_energy(self, device)

   device:emit_event_for_endpoint("main", capabilities.powerMeter.power({value = 0, unit = "W" }))

   --- Energy calculation
   --local current_level = device:get_latest_state("main", capabilities.switchLevel.ID, capabilities.switchLevel.level.NAME)
   --current_level = tonumber(current_level)
   local power_time = (os.time() - device:get_field("power_time_ini")) / 3600
   local energy_Total = device:get_field("energy_Total") + (power_time * device.preferences.loadPower / 1000)
   local energy_event = tonumber(string.format("%.3f",energy_Total))
   device:emit_event_for_endpoint("main", capabilities.energyMeter.energy({value = energy_event, unit = "kWh" }))
   device:set_field("energy_Total", energy_Total, {persist = false})
   device:set_field("energy_Total_persist", energy_Total, {persist = true})
   device:set_field("power_time_ini", os.time(), {persist = false})

end

---------------------------------------------------------
----on_off_attr_handler
function driver_handler.on_off_attr_handler(self, device, value, zb_rx)
  print("value.value >>>>>>>>>>>", value.value)
 if value.value == false or value.value == true then
  print("<<<<<<< Power meter Timer >>>>>", device:get_field("power_meter_timer"))
  local attr = capabilities.switch.switch
  device:emit_event_for_endpoint(zb_rx.address_header.src_endpoint.value, value.value and attr.on() or attr.off())

  --- Calculate power and energy
  if value.value == false and device:get_field("last_state") == "on" then

   -- save power consumption
   device:set_field("last_state", "off", {persist = false})
   save_energy(self, device)
   
   if device:get_field("random_state") == "Inactive" then
   ---- Timers Cancel ------
      for timer in pairs(device.thread.timers) do
       print("<<<<< Cancelando timer >>>>>")
       device:set_field("power_meter_timer", "OFF", {persist = true})
       device.thread:cancel_timer(timer)
      end 
    end
    
  elseif value.value == true then --- switch turn On
  --re-start power_time_ini if previous state is off
   if device:get_field("last_state") == "off" then device:set_field("power_time_ini", os.time(), {persist = false}) end
   device:set_field("last_state", "on", {persist = false})

   -- start power consumption
   local power = device.preferences.loadPower
   device:emit_event_for_endpoint("main", capabilities.powerMeter.power({value = power, unit = "W" }))

  ------ Timer activation
  if device:get_field("power_meter_timer") ~= "ON" and device.preferences.loadPower > 0 then

   device:set_field("power_time_ini", os.time(), {persist = false})

   device:set_field("power_meter_timer", "ON", {persist = true})
   device.thread:call_on_schedule(
    device.preferences.powerTimer * 60,
   function ()
    print("<<<<<<<<<< TIMER >>>>>>>")

    if device:get_field("last_state") == "on" then
    --if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on" then
      power = device.preferences.loadPower
      --- Energy calculation
      local power_time = (os.time() - device:get_field("power_time_ini")) / 3600
      device:set_field("power_time_ini", os.time(), {persist = false})
      device:emit_event_for_endpoint("main", capabilities.powerMeter.power({value = power, unit = "W" }))
      local energy_Total = device:get_field("energy_Total") + (power_time * power / 1000)
      local energy_event = tonumber(string.format("%.3f",energy_Total))
      device:emit_event_for_endpoint("main", capabilities.energyMeter.energy({value = energy_event, unit = "kWh" }))

      device:set_field("energy_Total", energy_Total, {persist = false})
      ---- re-start timer if preferences changed
      if device:get_field("powerTimer_Changed") == "Yes" then
        device:set_field("powerTimer_Changed", "No", {persist = false})
       ---- Timers Cancel ------
        for timer in pairs(device.thread.timers) do
          print("<<<<< Cancelando timer >>>>>")
          device:set_field("power_meter_timer", "OFF", {persist = true})
          device.thread:cancel_timer(timer)
        end 
      end
    end
   end
  ,'Power') 
   end 
  end
 end
end

 --------------------------------------------------------
 --------- Handler Random ON-OFF ------------------------

function driver_handler.random_on_off_handler(self,device,command)

  ---- Timers Cancel ------
  for timer in pairs(device.thread.timers) do
    print("<<<<< Cancel all timer >>>>>")
    device:set_field("power_meter_timer", "OFF", {persist = true})
    device.thread:cancel_timer(timer)
  end
  
  local random_state = "-"
  local nextChange = "Inactive"
  if command == "Active" then
    --random_state = "Active"
    random_state = device:get_field("random_state")
  else
    random_state = command.args.value
  end
  --print("randomOnOff Value", command.args.value)
  print("randomOnOff Value", random_state)
  if random_state == "Inactive" then
   -- send zigbee event
   device:send(OnOff.server.commands.Off(device))
   device:set_field("last_state", "off", {persist = false})
   device:emit_event(random_On_Off.randomOnOff("Inactive"))

   --emit time for next change
   nextChange = "Inactive"
   device:emit_event(random_Next_Step.randomNext(nextChange))
   device:set_field("random_state", "Inactive", {persist = true})
   save_energy(self, device)

 elseif random_state == "Random" or random_state == "Program" then
  device:emit_event(random_On_Off.randomOnOff(random_state))
  device:set_field("random_state", random_state, {persist = true})

  if random_state == "Random" then
   --Random timer calculation
   random_timer[device] = math.random(device.preferences.randomMin * 60, device.preferences.randomMax * 60)
   random_Step[device] = 0
   random_totalStep[device] = math.ceil(random_timer[device] / 30)
   nextChange= os.date("%H:%M:%S",os.time() + random_timer[device] + device.preferences.localTimeOffset * 3600)
  else
   device:send(OnOff.server.commands.On(device))
   device:set_field("last_state", "on", {persist = false})
   --Program timer calculation
   random_timer[device] = device.preferences.onTime * 60
   random_Step[device] = 0
   random_totalStep[device] = math.ceil(random_timer[device] / 30)
   nextChange= os.date("%H:%M:%S",os.time() + random_timer[device] + device.preferences.localTimeOffset * 3600)
  end

  --emit time for next change
  device:emit_event(random_Next_Step.randomNext(nextChange))
  print("random_totalStep=",random_totalStep[device])
  print("NextChange=",nextChange)

------ Timer activation
  device.thread:call_on_schedule(
  30,
  function ()
   random_Step[device] = random_Step[device] + 1
   print("random_step, random_totalStep=",random_Step[device],random_totalStep[device])

   if random_Step[device] >= random_totalStep[device] then

    if device:get_latest_state("main", capabilities.switch.ID, capabilities.switch.switch.NAME) == "on" then
      device:send(OnOff.server.commands.Off(device))
      device:set_field("last_state", "off", {persist = false})
      save_energy(self, device)
    else
       device:send(OnOff.server.commands.On(device))
       device:set_field("power_time_ini", os.time(), {persist = false})
       device:set_field("last_state", "on", {persist = false})
    end    
    
    if random_state == "Random" then
     random_timer[device] = math.random(device.preferences.randomMin * 60, device.preferences.randomMax * 60)
     random_Step[device] = 0
     random_totalStep[device] = math.ceil(random_timer[device] / 30)
     nextChange= os.date("%H:%M:%S",os.time() + random_timer[device] + device.preferences.localTimeOffset * 3600)
    else
     --Program timer calculation
     if device:get_field("last_state") == "on" then
      random_timer[device] = device.preferences.onTime * 60
     else
      random_timer[device] = device.preferences.offTime * 60
     end 
     random_Step[device] = 0
     random_totalStep[device] = math.ceil(random_timer[device] / 30)
     nextChange= os.date("%H:%M:%S",os.time() + random_timer[device] + device.preferences.localTimeOffset * 3600)
    end
    --emit time for next change
    device:emit_event(random_Next_Step.randomNext(nextChange))
    print("NEW-random_totalStep=",random_totalStep[device])
    print("NextChange=",nextChange)
   end
  end
  ,'Random-ON-OFF')   
 end
end

  return driver_handler