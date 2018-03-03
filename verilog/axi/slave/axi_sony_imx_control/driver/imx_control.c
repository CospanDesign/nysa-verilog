
#include <stdio.h>
#include <stdbool.h>

#include "sleep.h"
#include "xil_io.h"
#include "xil_types.h"
#include "imx_control.h"

const uint32_t MAX_CAMERA_COUNT            = 3;
const uint32_t MAX_LANE_WIDTH              = 16;

const uint32_t REG_CONTROL                 = 0 << 2;
const uint32_t REG_STATUS                  = 1 << 2;
const uint32_t REG_TRIGGER_PULSE_WIDTH     = 3 << 2;
const uint32_t REG_TRIGGER_PERIOD          = 4 << 2;
const uint32_t REG_CAMERA_COUNT            = 5 << 2;
const uint32_t REG_LANE_WIDTH              = 6 << 2;
const uint32_t REG_ALIGNED_FLAG_LOW        = 7 << 2;
const uint32_t REG_ALIGNED_FLAG_HIGH       = 8 << 2;

const uint32_t REG_TAP_DELAY_START         = 16 << 2;
const uint32_t SIZE_TAP_DELAY              = 3 * 16;
const uint32_t REG_VERSION                 = REG_TAP_DELAY_START + (SIZE_TAP_DELAY << 2);

const uint32_t CTRL_BIT_CLEAR              = 0;
const uint32_t CTRL_BIT_TAP_DELAY_RST      = 1;
const uint32_t CTRL_BIT_TRIGGER_EN         = 2;

const uint32_t CTRL_BIT_STROBE_CAM_CLK_RST = 4;
const uint32_t CTRL_BIT_STROBE_CAM_RST     = 5;

const uint32_t CTRL_BIT_POWER_EN0          = 12;
const uint32_t CTRL_BIT_POWER_EN1          = 13;
const uint32_t CTRL_BIT_POWER_EN2          = 14;


//Private Function Prototypes
uint32_t imxc_read_register(imx_control_t *ic, uint32_t address);
void imxc_write_register(imx_control_t *ic, uint32_t address, uint32_t value);
void imxc_enable_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index, bool enable);
void imxc_set_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index);
void imxc_clear_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index);
bool imxc_is_register_bit_set(imx_control_t *ic, uint32_t address, uint32_t bit_index);

int setup_imx_control(imx_control_t * ic, uint32_t base_address){
  int retval = XST_SUCCESS;
  ic->base_address = base_address;
  return retval;
}

uint32_t imx_control_get_status(imx_control_t * ic){
  return imxc_read_register(ic, REG_STATUS);
}
uint32_t imx_control_get_version(imx_control_t *ic){
  return imxc_read_register(ic, REG_VERSION);
}
int imx_control_setup_trigger(imx_control *ic, uint32_t period, uint32_t pulse_width){
  imxc_write_register(REG_TRIGGER_PULSE_WIDTH, pulse_width);
  imxc_write_register(REG_TIRGGER_PERIOD, period);
}
uint8_t imx_control_get_camera_count(imx_control_t *ic){
  return (uint8_t) imxc_read_register(ic, REG_CAMERA_COUNT);
}
uint8_t imx_control_get_lane_width(imx_control_t *ic){
  return (uint8_t) imxc_read_register(ic, REG_LANE_WIDTH);
}
uint64_t imx_control_get_align_flags(imx_control_t *ic){
  uint64_t flags = 0;
  flags = (imxc_read_register(ic, REG_ALIGNED_FLAG_HIGH) << 32);
  flags |= imxc_read_register(ic, READ_ALIGNED_FLAG_LOW);
  return flags;
}
uint32_t imx_control_get_camera_align_flags(imx_control_t *ic, uint8_t cam_index){
  uint64_t flags = imx_control_align_flags(ic);
  if (index >= MAX_CAMERA_COUNT)
    return 0xFFFF0000;
  return (flags >> (cam_index * MAX_LANE_WIDTH) & ((1 << MAX_LANE_WIDTH) - 1);
}
bool imx_control_is_all_camera_lanes_aligned(imx_control_it *ic, uint8_t cam_index){
  uint32_t flags = imx_control_get_camera_flags(ic, cam_index);
  uint8_t lanes = imx_control_get_lane_width(ic);
  uint32_t mask = (1 << lanes) - 1;

  if (flags == 0xFFFF0000)
    return false;
  return (flags == mask);
}

void imx_control_reset_async_cam_clock(imx_control_t * ic){
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_STROBE_CAM_CLK_RST, true);
}
void imx_control_reset_sync_cam_clock_domain(imx_control_t *ic){
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_STROBE_CAM_RST, true);
}
void imx_control_reset_camera(imx_control_t *ic){
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_STROBE_CLEAR, true);
  usleep(1000); //Sleep for 1msec
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_STROBE_CLEAR, false);
}
void imx_control_reset_tap_delay(imx_control_t *ic){
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_TAP_DELAY_RST, true);
  usleep(1000); //Sleep for 1msec
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_TAP_DELAY_RST, false);
}
int imx_control_enable_camera_power(imx_control_t *ic, uint8_t index,  bool enable){
  if (index >= MAX_CAMERA_COUNT)
    return XST_ERROR;
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_POWER_EN0 + index, enable);
  return XST_SUCCESS;
}
void imx_control_enable_camera_trigger(imx_control_t *ic, bool enable){ 
  imxc_enable_register_bit(ic, REG_CONTROL, CTRL_BIT_TRIGGER_EN, enable);
}
int imx_control_set_tap_delay(imx_control_t *ic, uint8_t cam_index, uint8_t lane_index, uint32_t delay){
  uint32_t tap_address = cam_index * MAX_LANE_WIDTH + lane_index;
  if (tap_address > (MAX_CAMERA_COUNT + MAX_LANE_WIDTH)){
    return XST_ERROR;
  tap_address = tap_address << 2;
  imxc_write_register(ic, REG_TAP_DELAY_START + tap_address, delay);
  return XST_SUCCESS;
}
uint32_t imx_control_get_tap_delay(imx_control_t *ic, uint8_t cam_index){
  uint32_t tap_address = cam_index * MAX_LANE_WIDTH + lane_index;
  if (tap_address > (MAX_CAMERA_COUNT + MAX_LANE_WIDTH)){
    return 0xFFFFFFFF;
  tap_address = tap_address << 2;
  return imxc_read_register(ic, REG_TAP_DELAY_START + tap_address);
}

//**************** PRIVATE FUNCTIONS *****************************************

uint32_t imxc_read_register(imx_control_t *ic, uint32_t address){
  return Xil_In32(ic->base_address + address);    
}
void imxc_write_register(imx_control_t *ic, uint32_t address, uint32_t value){
  Xil_Out32(ic->base_address + address, value);
}
void imxc_enable_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index, bool enable){
  if (enable)
    imxc_set_register_bit(ic, address, bit_index);
  else
    imxc_clear_register_bit(ic, address, bit_index);
}
void imxc_set_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index){
  uint32_t value = imxc_read_register(ic, address);
  value |= 1 << bit_index;
  imxc_write_register(ic, address, value);
}
void imxc_clear_register_bit(imx_control_t *ic, uint32_t address, uint32_t bit_index){
  uint32_t value = imxc_read_register(ic, address);
  value &= ~(1 << bit_index);
  imxc_write_register(ic, address, value);
}
bool imxc_is_register_bit_set(imx_control_t *ic, uint32_t address, uint32_t bit_index){
  uint32_t value = imxc_read_register(ic, address);
  return ((value & 1 << bit_index) > 0);
}



