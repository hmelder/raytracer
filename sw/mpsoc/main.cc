
#include "color.hpp"
#include "ray.hpp"
#include "scene.hpp"
#include "vec3.hpp"

#include "xaxidma.h"
#include "xparameters.h"
#include "xtmrctr.h"

#include <iostream>
#include <vector>

#define DMA_DEV_ID XPAR_AXIDMA_0_DEVICE_ID
#define DDR_BASE_ADDR XPAR_PSU_DDR_0_S_AXI_BASEADDR
#define MEM_BASE_ADDR (DDR_BASE_ADDR + 0x1000000)

#define TX_BUFFER_BASE (MEM_BASE_ADDR + 0x00100000)
#define RX_BUFFER_BASE (MEM_BASE_ADDR + 0x00300000)

#define TIMER_COUNTER_0 0
#define TMRCTR_DEVICE_ID XPAR_TMRCTR_0_DEVICE_ID

XAxiDma AxiDma;
XTmrCtr TimerCounter;

uint32_t *TxBufferPtr = (u32 *)TX_BUFFER_BASE;
uint32_t *RxBufferPtr = (u32 *)RX_BUFFER_BASE;

static const int image_width = 32;
static const float focal_length = 1.0f;
static const float aspect_ratio = 1.0f;

int dma_transfer(size_t tx_length, size_t rx_length, u16 DeviceId) {
  XAxiDma_Config *CfgPtr;
  int Status;

  /* Initialize the XAxiDma device.
   */
  CfgPtr = XAxiDma_LookupConfig(DeviceId);
  if (!CfgPtr) {
    xil_printf("No config found for %d\r\n", DeviceId);
    return XST_FAILURE;
  }

  Status = XAxiDma_CfgInitialize(&AxiDma, CfgPtr);
  if (Status != XST_SUCCESS) {
    xil_printf("Initialization failed %d\r\n", Status);
    return XST_FAILURE;
  }

  if (XAxiDma_HasSg(&AxiDma)) {
    xil_printf("Device configured as SG mode \r\n");
    return XST_FAILURE;
  }

  /* Disable interrupts, we use polling mode
   */
  XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DEVICE_TO_DMA);
  XAxiDma_IntrDisable(&AxiDma, XAXIDMA_IRQ_ALL_MASK, XAXIDMA_DMA_TO_DEVICE);

  /* Flush the buffers before the DMA transfer, in case the Data Cache
   * is enabled
   */
  Xil_DCacheFlushRange((UINTPTR)TxBufferPtr, tx_length);
  Xil_DCacheFlushRange((UINTPTR)RxBufferPtr, rx_length);

  Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)TxBufferPtr, tx_length,
                                  XAXIDMA_DMA_TO_DEVICE);
  if (Status != XST_SUCCESS) {
    xil_printf("Failed to send configuration to co-processor\n");
    return XST_FAILURE;
  }

  while (XAxiDma_Busy(&AxiDma, XAXIDMA_DMA_TO_DEVICE)) {
  }

  Xil_DCacheInvalidateRange((UINTPTR)RxBufferPtr, rx_length);
  Status = XAxiDma_SimpleTransfer(&AxiDma, (UINTPTR)RxBufferPtr, rx_length,
                                  XAXIDMA_DEVICE_TO_DMA);

  if (Status != XST_SUCCESS) {
    xil_printf("Failed to receive response\n");
    return XST_FAILURE;
  }

  while (XAxiDma_Busy(&AxiDma, XAXIDMA_DEVICE_TO_DMA)) {
  }

  /* Invalidate the DestBuffer before receiving the data, in case the
   * Data Cache is enabled
   */

  return XST_SUCCESS;
}

color ray_color(const ray &r) {
  vec3 unit_direction = unit_vector(r.direction());
  auto a = 0.5 * (unit_direction.y() + 1.0);
  return (1.0 - a) * color(1.0, 1.0, 1.0) + a * color(0.5, 0.7, 1.0);
}

/*
int main() {
        Scene scene(400.0f, 16.0f/9.0f, 1.0f);
        uint32_t *cam = scene.serialised();

        for (int i = 0; i < SCENE_PAYLOAD_SIZE; i++) {
                TxBufferPtr[i] = cam[i];
        }

        dma_transfer(SCENE_PAYLOAD_SIZE*4, SCENE_PAYLOAD_SIZE*4, DMA_DEV_ID);

        for (int i = 0; i < SCENE_PAYLOAD_SIZE; i++) {
                uint32_t actual = RxBufferPtr[i];
                uint32_t expected = cam[i];
                if (actual != expected) {
                        std::cout << "Test failed at i = " << i << ", expected "
<< expected << " but got " << actual << std::endl;
                }
        }

        std::cout << "Finished!" << std::endl;
 }*/

int main() {
  // Timer Configuration
  XTmrCtr *TmrCtrInstancePtr = &TimerCounter;
  u8 TmrCtrNumber = TIMER_COUNTER_0;
  if (XTmrCtr_Initialize(TmrCtrInstancePtr, TMRCTR_DEVICE_ID) != XST_SUCCESS) {
    std::cout << " Failed to initialize timer" << std::endl;
    return XST_FAILURE;
  }

  if (XTmrCtr_SelfTest(TmrCtrInstancePtr, TmrCtrNumber) != XST_SUCCESS) {
    std::cout << "Timer self-test failed" << std::endl;
    return XST_FAILURE;
  }

  XTmrCtr_SetOptions(TmrCtrInstancePtr, TmrCtrNumber, XTC_AUTO_RELOAD_OPTION);

  Scene scene(image_width, aspect_ratio, focal_length);
  uint32_t *cam = scene.serialised();

  for (int i = 0; i < SCENE_PAYLOAD_SIZE; i++) {
    TxBufferPtr[i] = cam[i];
  }

  std::cout << "Starting DMA transaction...." << std::endl;
  // Transfer the scene configuration to the co-processor
  XTmrCtr_Start(TmrCtrInstancePtr, TmrCtrNumber);
  u32 before_dma = XTmrCtr_GetValue(TmrCtrInstancePtr, TmrCtrNumber);

  size_t tx_len = SCENE_PAYLOAD_SIZE * 4;
  size_t rx_len = int(scene.image_height) * int(scene.image_width);
  int rc = dma_transfer(tx_len, rx_len, DMA_DEV_ID);

  u32 after_dma = XTmrCtr_GetValue(TmrCtrInstancePtr, TmrCtrNumber);
  XTmrCtr_Stop(TmrCtrInstancePtr, TmrCtrNumber);
  if (rc != XST_SUCCESS) {
    return -1;
  }
  std::cout << "DMA Transaction finished" << std::endl;

  uint32_t *RxBuffer = (u32 *)RX_BUFFER_BASE;
  std::cout << "DMA took " << (after_dma - before_dma) << " times units"
            << std::endl;

  int image_height = int(scene.image_height);
  for (int i = 0; i < image_height * image_width; i++) {
    xil_printf("0x%x,\n", RxBuffer[i]);
  }

  XTmrCtr_Start(TmrCtrInstancePtr, TmrCtrNumber);
  u32 before_sw = XTmrCtr_GetValue(TmrCtrInstancePtr, TmrCtrNumber);

  // Ray Generation in software
  volatile size_t dummy_sum = 0; // do not optimise
  for (int h = 0; h < image_height; ++h) {
    for (int w = 0; w < image_width; ++w) {
      auto pixel_center = scene.pixel_00_loc + (w * scene.pixel_delta_u) +
                          (h * scene.pixel_delta_v);
      auto ray_direction = pixel_center - scene.camera_center;
      ray r(scene.camera_center, ray_direction);
      dummy_sum += reinterpret_cast<size_t>(&r);
    }
  }
  u32 after_sw = XTmrCtr_GetValue(TmrCtrInstancePtr, TmrCtrNumber);
  XTmrCtr_Stop(TmrCtrInstancePtr, TmrCtrNumber);

  std::cout << "SW took " << (after_sw - before_sw)
            << " times units. after: " << after_sw << " before: " << before_sw
            << std::endl;

  std::cout << "Image with rays from hardware" << std::endl;

  std::cout << "P3\n" << image_width << ' ' << image_height << "\n255\n";
  for (int h = 0; h < image_height; h++) {
    for (int w = 0; w < image_width; w++) {
      int32_t raw_y = RxBuffer[w + image_width * h];
      vec3 ray_direction = vec3(0, FIX_2_FLOAT(raw_y), -1);
      ray r(scene.camera_center, ray_direction);
      write_color(std::cout, ray_color(r));
    }
  }
  puts("\n");

  std::cout << "Image with rays from software" << std::endl;

  std::cout << "P3\n" << image_width << ' ' << image_height << "\n255\n";
  for (int h = 0; h < image_height; h++) {
    for (int w = 0; w < image_width; w++) {
      auto pixel_center = scene.pixel_00_loc + (w * scene.pixel_delta_u) +
                          (h * scene.pixel_delta_v);
      auto ray_direction = pixel_center - scene.camera_center;
      ray r(scene.camera_center, vec3(0, ray_direction[1], -1));
      write_color(std::cout, ray_color(r));
    }
  }

  XTmrCtr_SetOptions(TmrCtrInstancePtr, TmrCtrNumber, 0);

  return 0;
}
