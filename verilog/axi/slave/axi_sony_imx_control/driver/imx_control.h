#ifndef __SONY_CAMERA_CONTROL_H__
#define __SONY_CAMERA_CONTROL_H__


#ifdef __cplusplus
extern "C"{
#endif

#include <stdint.h>


typedef struct {
  uint32_t base_address;
} imx_control_t;


int setup_imx_control(imx_control_t * ic, uint32_t base_address);
uint32_t imx_control_get_status(imx_control_t * ic);
uint32_t imx_control_get_version(imx_control_t *ic);
int imx_control_setup_trigger(imx_control *ic, uint32_t period, uint32_t pulse_width);
uint8_t imx_control_get_camera_count(imx_control_t *ic);
uint8_t imx_control_get_lane_width(imx_control_t *ic);
uint64_t imx_control_get_align_flags(imx_control_t *ic);
uint32_t imx_control_get_camera_align_flags(imx_control_t *ic, uint8_t cam_index);
bool imx_control_is_all_camera_lanes_aligned(imx_control_it *ic, uint8_t cam_index);
void imx_control_reset_async_cam_clock(imx_control_t * ic);
void imx_control_reset_sync_cam_clock_domain(imx_control_t *ic);
void imx_control_reset_camera(imx_control_t *ic);
void imx_control_reset_tap_delay(imx_control_t *ic);
int imx_control_enable_camera_power(imx_control_t *ic, uint8_t index, bool enable);
void imx_control_enable_camera_trigger(imx_control_t *ic, bool enable);
int imx_control_set_tap_delay(imx_control_t *ic, uint8_t cam_index, uint8_t lane_index, uint32_t delay);
uint32_t imx_control_get_tap_delay(imx_control_t *ic, uint8_t cam_index);


#ifdef __cplusplus
} // extern "C"
#endif

#endif
