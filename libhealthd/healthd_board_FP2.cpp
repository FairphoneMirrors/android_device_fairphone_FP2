
/*
* Copyright (C) 2013 The Android Open Source Project
*
* Licensed under the Apache License, Version 2.0 (the "License");
* you may not use this file except in compliance with the License.
* You may obtain a copy of the License at
*
*      http://www.apache.org/licenses/LICENSE-2.0
*
* Unless required by applicable law or agreed to in writing, software
* distributed under the License is distributed on an "AS IS" BASIS,
* WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
* See the License for the specific language governing permissions and
* limitations under the License.
*/

#include <fcntl.h>
#include <healthd.h>
#include <inttypes.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/stat.h>
#include <sys/types.h>
#include <unistd.h>

#include <cutils/android_reboot.h>
#include <cutils/klog.h>

#define BACKLIGHT_ON_LEVEL    100
#define BACKLIGHT_OFF_LEVEL    0

#define RED_LED_PATH            "/sys/class/leds/red/brightness"
#define GREEN_LED_PATH          "/sys/class/leds/green/brightness"
#define BLUE_LED_PATH           "/sys/class/leds/blue/brightness"
#define BACKLIGHT_PATH          "/sys/class/leds/lcd-backlight/brightness"
#define CHARGING_ENABLED_PATH   "/sys/class/power_supply/battery/charging_enabled"

#define ARRAY_SIZE(x)           (sizeof(x)/sizeof(x[0]))

#define LOGE(x...) do { KLOG_ERROR("charger", x); } while (0)
#define LOGW(x...) do { KLOG_WARNING("charger", x); } while (0)
#define LOGV(x...) do { KLOG_DEBUG("charger", x); } while (0)

enum {
  RED_LED = 0x01 << 0,
  GREEN_LED = 0x01 << 1,
  BLUE_LED = 0x01 << 2,
};

struct led_ctl {
  int color;
  const char *path;
};

struct led_ctl leds[3] =
{{RED_LED, RED_LED_PATH},
{GREEN_LED, GREEN_LED_PATH},
{BLUE_LED, BLUE_LED_PATH}};

struct soc_led_color_mapping {
  int soc;
  int color;
};

/* Increasing battery charge percentage vs LED color mapping */
struct soc_led_color_mapping soc_leds[3] = {
  {15, RED_LED},
  {95, RED_LED | GREEN_LED},
  {100, GREEN_LED},
};

static int set_tricolor_led(int on, int color)
{
  int fd, i;
  char buffer[10];
  
  for (i = 0; i < (int)ARRAY_SIZE(leds); i++) {
    if ((color & leds[i].color) && (access(leds[i].path, R_OK | W_OK) == 0)) {
      fd = open(leds[i].path, O_RDWR);
      if (fd < 0) {
        LOGE("Could not open red led node\n");
        goto cleanup;
      }
      if (on)
      snprintf(buffer, sizeof(int), "%d\n", 255);
      else
      snprintf(buffer, sizeof(int), "%d\n", 0);
      
      if (write(fd, buffer, strlen(buffer)) < 0)
      LOGE("Could not write to led node\n");
      cleanup:
      if (fd >= 0)
      close(fd);
    }
  }
  
  return 0;
}

static int set_battery_soc_leds(int soc)
{
  int i, color;
  static int old_color = -1;
  int range_max = ARRAY_SIZE(soc_leds) - 1;
  
  if (range_max < 0)
  return 0;
  
  color = soc_leds[range_max].color;
  for (i = 0; i <= range_max ; i++) {
    if (soc < soc_leds[i].soc) {
      color = soc_leds[i].color;
      break;
    }
  }
  if (old_color != color) {
    if (old_color >= 0)
    set_tricolor_led(0, old_color);
    set_tricolor_led(1, color);
    old_color = color;
  }
  
  return 0;
}

static int is_usb_charger_valid()
{
  const char *usb_charger_path = "/sys/kernel/debug/msm_otg/chg_type";
  char buf[32] = {'\0'};
  int fd = 0;
  int open_count = 3;
  int sleep_count = 0;
  
  while ((fd <= 0) && (open_count-- > 0)) {
    fd = open(usb_charger_path, O_RDONLY);
    if (fd > 0) {
      break;
    }
    usleep(100000);
  }
  if (fd > 0) {
    while (!strstr(buf, "USB")  && (sleep_count <= 20)) {
      read(fd, buf, 32);
      if (strstr(buf, "USB")) {
        close(fd);
        return 1;
      } else {
        usleep(100000);
      }
      sleep_count++;
    }
  } else {
    sleep(2);
  }
  return 0;
}

static void wait_for_usb_ps_ok()
{
  const char *usb_ps_online = "/sys/class/power_supply/usb/online";
  char buf[8] = {'\0'};
  int fd = 0;
  int open_count = 3;
  int sleep_count = 0;
  
  while ((fd <= 0) && (open_count-- > 0)) {
    fd = open(usb_ps_online, O_RDONLY);
    if (fd > 0) {
      break;
    }
    usleep(100000);
  }
  if (fd > 0) {
    while ((buf[0] != '1') && (sleep_count <= 20)) {
      read(fd, buf, 2);
      if (buf[0] == '1') {
        close(fd);
        return;
      } else {
        usleep(100000);
      }
      sleep_count++;
    }
  } else {
    sleep(2);
  }
}

void healthd_board_init(struct healthd_config*)
{
  // use defaults
}


int healthd_board_battery_update(struct android::BatteryProperties*)
{
  // return 0 to log periodic polled battery status to kernel log
  return 0;
}

void healthd_board_mode_charger_draw_battery(struct android::BatteryProperties*)
{
  
}

void healthd_board_mode_charger_battery_update(struct android::BatteryProperties* props)
{
  static int old_soc = -1;
  int soc = props->batteryLevel;
  if (old_soc != soc) {
    old_soc = soc;
    set_battery_soc_leds(soc);
  }
}

void healthd_board_mode_charger_set_backlight(bool value)
{
  int fd;
  char buffer[10];
  
  if (access(BACKLIGHT_PATH, R_OK | W_OK) != 0)
  {
    LOGW("Backlight control not support\n");
  }
  
  memset(buffer, '\0', sizeof(buffer));
  fd = open(BACKLIGHT_PATH, O_RDWR);
  if (fd < 0) {
    LOGE("Could not open backlight node : %s\n", strerror(errno));
    goto cleanup;
  }
  LOGV("Enabling backlight\n");
  snprintf(buffer, sizeof(buffer), "%d\n",
  value?BACKLIGHT_ON_LEVEL:BACKLIGHT_OFF_LEVEL);
  if (write(fd, buffer,strlen(buffer)) < 0) {
    LOGE("Could not write to backlight node : %s\n", strerror(errno));
    goto cleanup;
  }
  cleanup:
  if (fd >= 0)
  close(fd);
}

void healthd_board_mode_charger_init()
{
  int ret;
  char buff[8] = "\0";
  int charging_enabled = 0;
  int fd;
  
  if (is_usb_charger_valid()) {
    wait_for_usb_ps_ok();
  }
  
  /* check the charging is enabled or not */
  fd = open(CHARGING_ENABLED_PATH, O_RDONLY);
  if (fd < 0)
  return;
  ret = read(fd, buff, sizeof(buff));
  close(fd);
  if (ret > 0 && sscanf(buff, "%d\n", &charging_enabled)) {
    /* if charging is disabled, reboot and exit power off charging */
    if (charging_enabled)
    return;
    LOGW("android charging is disabled, exit!\n");
    android_reboot(ANDROID_RB_RESTART, 0, 0);
  }
}
