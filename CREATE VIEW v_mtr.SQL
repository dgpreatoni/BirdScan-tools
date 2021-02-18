/* pull out MTR values, with any possible attribute: classification, time, elevation, blindness 
 * version 1.2
 * created  20199823 prea
 * modified 20210218 prea
 * */
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE VIEW v_mtr AS
SELECT 
  -- time coordinate
  tb.time_start AS time_stamp,
  tb.time_start,
  tb.time_stop,
  mtr.time_bin,
  -- elevation
  ab.mean_altitude,
  ab.from_altitude,
  ab.to_altitude,
  mtr.altitude_bin,
  -- weather properties (e.g. blind time)
  we.value AS blind_percent,
  -- signal class
  mtr.monitor_class,
  mc.name AS monitor_class_name,
  mc.description AS monitor_class_description,
  -- echo count (what is it?)
  mtr.echo_count,
  -- mtr raw walue
  mtr.mtr
FROM mtr
LEFT JOIN time_bins tb ON mtr.time_bin = tb.id 
LEFT JOIN altitude_bins ab ON mtr.altitude_bin = ab.id
LEFT JOIN weather we ON mtr.time_bin = we.time_bin 
LEFT JOIN monitor_classes mc ON mtr.monitor_class = mc.id 
WHERE we.weather_property = 5 -- i.e. blind time %
GO