#ifndef __SONY_CAMERA_CONTROL_H__
#define __SONY_CAMERA_CONTROL_H__


#ifdef __cplusplus
extern "C"{
#endif

#include "xil_types.h"

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
void imx_control_reset_async_cam_clock(imx_control_t * ic);
void imx_control_reset_sync_cam_clock_domain(imx_control_t *ic);
void imx_control_enable_cam_register_clear(imx_control_t *ic, int enable);
void imx_control_reset_tap_delay(imx_control_t *ic);
int imx_control_enable_camera_power(imx_control_t *ic, u8 index, int enable);
void imx_control_enable_camera_trigger(imx_control_t *ic, int enable);
int imx_control_set_tap_delay(imx_control_t *ic, u8 cam_index, u8 lane_index, u32 delay);
u32 imx_control_get_tap_delay(imx_control_t *ic, u8 cam_index, u8 lane_index);


#ifdef __cplusplus
} // extern "C"
#endif

#endif
