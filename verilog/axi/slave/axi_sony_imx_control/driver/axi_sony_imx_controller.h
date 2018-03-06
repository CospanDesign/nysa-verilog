#ifndef __SONY_CAMERA_CONTROL_H__
#define __SONY_CAMERA_CONTROL_H__


#ifdef __cplusplus
extern "C"{
#endif

#include "xil_types.h"

/******************************************************************************
 * Sequence of Steps
 *
 * Set Camera Power Low
 * Set Camera Clear Low
 * Set Camera Async Reset Low
 * Set Tap Delay Reset Low
 * Wait for ???
 * Set Camera Power High
 * Wait for ???
 * Set Camera Clear High
 * Wait for ???
 * Set Async Reset High
 * Wait for ???
 * Set Async Reset Low
 * Wait for ???
 * Set Sync Reset High
 * Wait for ???
 * Set Tap Delay Reset High
 * Wait for ???
 * Set Tap Delay Reset Low
 *
 *****************************************************************************/

typedef struct {
  u32 base_address;
} imx_control_t;

int setup_imx_control(imx_control_t * ic, u32 base_address);
u32 imx_control_get_status(imx_control_t * ic);
u32 imx_control_get_version(imx_control_t *ic);
void imx_control_setup_trigger(imx_control_t *ic, u32 period, u32 pulse_width);
u8 imx_control_get_camera_count(imx_control_t *ic);
u8 imx_control_get_lane_width(imx_control_t *ic);
u64 imx_control_get_align_flags(imx_control_t *ic);
u32 imx_control_get_camera_align_flags(imx_control_t *ic, u8 cam_index);
int imx_control_is_all_camera_lanes_aligned(imx_control_t *ic, u8 cam_index);


int imx_control_camera_power_enable(imx_control_t *ic, u8 cam_index, u8 enable);
void imx_control_cam_register_clear_enable(imx_control_t *ic, u8 enable);

void imx_control_reset_sync_cam_clock_domain(imx_control_t *ic);
void imx_control_reset_async_cam_clock_enable(imx_control_t * ic);
void imx_control_reset_tap_delay_enable(imx_control_t *ic, u8 enable);

void imx_control_camera_trigger_enable(imx_control_t *ic, u8 enable);

int imx_control_set_tap_delay(imx_control_t *ic, u8 cam_index, u8 lane_index, u32 delay);
u32 imx_control_get_tap_delay(imx_control_t *ic, u8 cam_index, u8 lane_index);


#ifdef __cplusplus
} // extern "C"
#endif

#endif
