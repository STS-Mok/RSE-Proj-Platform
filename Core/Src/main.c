/* USER CODE BEGIN Header */
/**
  ******************************************************************************
  * @file           : main.c
  * @brief          : Main program body
  * @log
  * 		25/03/2022		1.00		algo and tx to P1
  * 		23/03/2022		0.50		recieve and transmit info to terminal
  ******************************************************************************
  * @attention
  *
  * Copyright (c) 2022 STMicroelectronics.
  * All rights reserved.
  *
  * This software is licensed under terms that can be found in the LICENSE file
  * in the root directory of this software component.
  * If no LICENSE file comes with this software, it is provided AS-IS.
  *
  ******************************************************************************
  */
/* USER CODE END Header */
/* Includes ------------------------------------------------------------------*/
#include "main.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

#include <stdio.h>

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */

/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
UART_HandleTypeDef huart1;
UART_HandleTypeDef huart2;
UART_HandleTypeDef huart3;

/* USER CODE BEGIN PV */

int rx_gen[20];
int siginfo[7];

int* gen_rx = rx_gen;
int* rx_sig = siginfo;

int rx_buf_len, p1_buf_len;
char rx_buf[50], p1_buf[50];

/* USER CODE END PV */

/* Private function prototypes -----------------------------------------------*/
void SystemClock_Config(void);
static void MX_GPIO_Init(void);
static void MX_USART3_UART_Init(void);
static void MX_USART1_UART_Init(void);
static void MX_USART2_UART_Init(void);
/* USER CODE BEGIN PFP */

void getVersion(int* pckt) {
	uint8_t tx[] = {0xae, 0xc1, 0x0e, 0x00};
	uint8_t rx[13];

	HAL_UART_Transmit(&huart1, (uint8_t*)tx, sizeof(tx), 100);
	HAL_UART_Receive(&huart1, rx, sizeof(rx), 100);

	/*
	 * version_info[5]
	 * 0 = 16-bit hardware version
	 * 1 = firmware version (major)
	 * 2 = firmware version (minor)
	 * 3 = 16-bit firmware build
	 * 4 = checksum
	 */

	*pckt		= (int)(rx[7]<<8|rx[6]);
	*(pckt+1)	= (int)(rx[8]);
	*(pckt+2)	= (int)(rx[9]);
	*(pckt+3)	= (int)(rx[11]<<8|rx[10]);
	*(pckt+4)	= (int)(rx[5]<<8|rx[4]);

	int calc_cs;
	calc_cs = sizeof(rx);

	rx_buf_len = sprintf(rx_buf, "Hardware version: %d\r\n", pckt[0]);
	HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	rx_buf_len = sprintf(rx_buf, "Firmware: %d.%d.%d\r\n", pckt[1], pckt[2], pckt[3]);
	HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	rx_buf_len = sprintf(rx_buf, "Checksum: %d\r\n", pckt[4]);
	HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	rx_buf_len = sprintf(rx_buf, "Cal checksum: %d\r\n", calc_cs);
	HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);

}

void getResolution(int* pckt) {
	uint8_t tx[] = {0xae, 0xc1, 0x0c, 0x01, 0x00};
	uint8_t rx[10];

	HAL_UART_Transmit(&huart1, (uint8_t*)tx, sizeof(tx), 100);
	HAL_UART_Receive(&huart1, rx, sizeof(rx), 100);

	/*
	 * res_info[2]
	 * 0 = 16-bit frame width
	 * 1 = 16-bit frame height
	 */

	*pckt		= (int)(rx[7]<<8|rx[6]);
	*(pckt+1)	= (int)(rx[9]<<8|rx[8]);

}

void setBrightness(int brightness) {
	uint8_t tx[] = {0xae, 0xc1, 0x10, 0x01, brightness};
	uint8_t rx[10];

	HAL_UART_Transmit(&huart1, (uint8_t*)tx, sizeof(tx), 100);
	HAL_UART_Receive(&huart1, rx, sizeof(rx), 100);

}

void getBlocks(int* pckt, int sigmap, int maxBlocks) {
	uint8_t tx[] = {0xae, 0xc1, 0x20, 0x02, sigmap, maxBlocks};
	uint8_t rx[20];

	HAL_UART_Transmit(&huart1, (uint8_t*)tx, sizeof(tx), 100);
	HAL_UART_Receive(&huart1, rx, sizeof(rx), 100);

	/*
	 * sigInfo[]
	 * 0 = color code
	 * 1 = X center
	 * 2 = Y center
	 * 3 = width
	 * 4 = height
	 * 5 = track index
	 * 6 = age
	 */

	*pckt		= (int)(rx[7]<<8|rx[6]);
	*(pckt+1)	= (int)(rx[9]<<8|rx[8]);
	*(pckt+2)	= (int)(rx[11]<<8|rx[10]);
	*(pckt+3)	= (int)(rx[13]<<8|rx[12]);
	*(pckt+4)	= (int)(rx[15]<<8|rx[14]);
	*(pckt+5)	= (int)(rx[18]);
	*(pckt+6)	= (int)(rx[19]);
}

int adjSpd(int res_ht, int ht) {
	int speed;

	if (ht == res_ht)			speed = 0;
	else if (ht > res_ht/2)		speed = 25;
	else if (ht > res_ht/4)		speed = 50;
	else if (ht > res_ht/8)		speed = 75;
	else						speed = 100;

	/*
	if((height <= 102) && (height >= 61))	speed = 10;
	else	speed = 50;
	*/

	/*
	if		(ht > 104)	speed = 10;
	else if (ht > 52)	speed = 20;
	else if	(ht > 26)	speed = 35;
	else				speed = 50;
	*/

	return speed;
}

int adjDir(/*int res_w, int res_h,*/ int pos_x, int pos_y/*, int ht*/) {
	int ctr_x = 157;
	int ctr_y = 104;

	int diff_x = pos_x - ctr_x;
	int diff_y = pos_y - ctr_y;

	int dir;

	/*
	if(ht > (res_w/2)) {
		if		(diff_x < (-(3/4)*res_w))	dir = 22;	//dbl
		else if (diff_x > ((3/4)*res_w))	dir = 32;	//dbr
		else							dir = 12;	//bkd
	} else if (ht > (res_w/4)) {
		if		(diff_x < (-(3/4)*res_w))	dir = 20;	//lsf
		else if (diff_x > ((3/4)*res_w))	dir = 30;	//rsf
		else							dir = 1;	//stp
	} else {
		if		(diff_x < (-(3/4)*res_w))	dir = 21;	//lsf
		else if (diff_x > ((3/4)*res_w))	dir = 31;	//rsf
		else							dir = 11;	//stp
	}
	*/

	/*
	case LONG[mtrCmd]
      1:
        stp
      11:
        fwd(long[spd])
      12:
        bkd(long[spd])
      18:
        ccw(long[spd])
      19:
        ckw(long[spd])

      20:
        lsf(long[spd])
      21:
        dfl(long[spd])
      22:
        dbl(long[spd])
      28:
        cfl(long[spd])
      29:
        cbl(long[spd])

      30:
        rsf(long[spd])
      31:
        dfr(long[spd])
      32:
        dbr(long[spd])
      38:
        cfr(long[spd])
      39:
        cbr(long[spd])
	*/



	/*
	if (diff_y == 0){							//y at center
		if (diff_x == 0) dir = 1;
		else if (diff_x < 0) dir = 20;
		else if (diff_x > 0) dir = 30;
		else dir = 1;							//stop in case of anything
	} else if (diff_y < 0) {					//y is nearer
		if (diff_x == 0) dir = 12;
		else if (diff_x < 0) dir = 22;
		else if (diff_x > 0) dir = 32;
		else dir = 1;
	} else if (diff_y > 0) {					//y is further
		if (diff_x == 0) dir = 11;
		else if (diff_x < 0) dir = 21;
		else if (diff_x > 0) dir = 31;
		else dir = 1;
	}
	*/


	if (diff_y > -10){
		if (diff_x < -20) dir = 21;
		else if (diff_x < 20) dir = 11;
		else dir = 31;
	} else if (diff_y > 50){
		if (diff_x < 40) dir = 20;
		else if (diff_x < 35) dir = 1;
		else dir = 30;
	} else {
		if (diff_x < -80) dir = 22;
		else if (diff_x < 70) dir = 12;
		else dir = 32;
	}


	/*
	if (ht < 52){
		if (diff_x < -20) dir = 21;
		else if (diff_x < 20) dir = 11;
		else dir = 31;
	} else if (ht < 104){
		if (diff_x < 40) dir = 20;
		else if (diff_x < 35) dir = 1;
		else dir = 30;
	} else {
		if (diff_x < -80) dir = 22;
		else if (diff_x < 70) dir = 12;
		else dir = 32;
	}
	*/

	return dir;
}
/* USER CODE END PFP */

/* Private user code ---------------------------------------------------------*/
/* USER CODE BEGIN 0 */

/* USER CODE END 0 */

/**
  * @brief  The application entry point.
  * @retval int
  */
int main(void)
{
  /* USER CODE BEGIN 1 */

  /* USER CODE END 1 */

  /* MCU Configuration--------------------------------------------------------*/

  /* Reset of all peripherals, Initializes the Flash interface and the Systick. */
  HAL_Init();

  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* Configure the system clock */
  SystemClock_Config();

  /* USER CODE BEGIN SysInit */

  /* USER CODE END SysInit */

  /* Initialize all configured peripherals */
  MX_GPIO_Init();
  MX_USART3_UART_Init();
  MX_USART1_UART_Init();
  MX_USART2_UART_Init();
  /* USER CODE BEGIN 2 */

  getVersion(gen_rx);
  getResolution(gen_rx);

  /* USER CODE END 2 */

  /* Infinite loop */
  /* USER CODE BEGIN WHILE */
  while (1)
  {

	  //debugging - show all vals


	  getBlocks(rx_sig, 0x01, 0x01);

	  /*
	  rx_buf_len = sprintf(rx_buf, "x center: %d\r\n", siginfo[1]);
	  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	  rx_buf_len = sprintf(rx_buf, "y center: %d\r\n", siginfo[2]);
	  HAL_UART_Transmit (&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	  rx_buf_len = sprintf(rx_buf, "width: %d\r\n", siginfo[3]);
	  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	  rx_buf_len = sprintf(rx_buf, "height: %d\r\n", siginfo[4]);
	  HAL_UART_Transmit (&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	  rx_buf_len = sprintf(rx_buf, "age: %d\r\n", siginfo[6]);
	  HAL_UART_Transmit (&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
	  */

	  int dir = 1;
	  int spd = 0;

	  if(siginfo[6] == 0){
		  rx_buf_len = sprintf(rx_buf, "No signiture detected\r\n");
		  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
		  spd = 0;
	  } else {
		  spd = adjSpd((int)rx_gen, (int)siginfo[4]);
		  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
		  dir = adjDir(/*(int)rx_gen[0], (int)rx_gen[1],*/ (int)siginfo[1], (int)siginfo[2]/*, (int)siginfo[4]*/);
		  switch(dir) {

		  case 1 :		//stop
			  spd = 0;
			  rx_buf_len = sprintf(rx_buf, "stop\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 20:
			  rx_buf_len = sprintf(rx_buf, "strafe left\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 30:
			  rx_buf_len = sprintf(rx_buf, "strafe right\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;

		  case 12:
			  rx_buf_len = sprintf(rx_buf, "reverse\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 22:
			  rx_buf_len = sprintf(rx_buf, "diagonal back left\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 32:
			  rx_buf_len = sprintf(rx_buf, "diagonal back right\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;

		  case 11:
			  rx_buf_len = sprintf(rx_buf, "forward\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 21:
			  rx_buf_len = sprintf(rx_buf, "diagonal front left\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  case 31:
			  rx_buf_len = sprintf(rx_buf, "diagonal front right\r\n");
			  HAL_UART_Transmit(&huart2, (uint8_t*)rx_buf, rx_buf_len, 100);
			  break;
		  }
	  }

	  uint8_t p1_tx[4];

	  int cs = (p1_tx[1]^=p1_tx[2]);

  	  p1_tx[0] = 0x7A;		//start byte
  	  p1_tx[1] = dir;		//direction
  	  p1_tx[2] = spd;		//speed
  	  p1_tx[3] = ( cs ^= 0x7F);		//cs

  	  rx_buf_len = sprintf(rx_buf, "speed: %d\r\n", (uint8_t)spd);
  	  p1_buf_len = sprintf(p1_buf, "sending pckt\r\n");
  	  HAL_UART_Transmit(&huart2, (uint8_t*)p1_buf, p1_buf_len, 100);

  	  HAL_UART_Transmit(&huart3, (uint8_t*)p1_tx, sizeof(p1_tx), 100);

  	  p1_buf_len = sprintf(p1_buf, "pckt sent\r\n");
  	  HAL_UART_Transmit(&huart2, (uint8_t*)p1_buf, p1_buf_len, 100);
	  //HAL_Delay(500);

  }
    /* USER CODE END WHILE */
    /* USER CODE BEGIN 3 */

  /* USER CODE END 3 */
}

/**
  * @brief System Clock Configuration
  * @retval None
  */
void SystemClock_Config(void)
{
  RCC_OscInitTypeDef RCC_OscInitStruct = {0};
  RCC_ClkInitTypeDef RCC_ClkInitStruct = {0};

  /** Initializes the RCC Oscillators according to the specified parameters
  * in the RCC_OscInitTypeDef structure.
  */
  RCC_OscInitStruct.OscillatorType = RCC_OSCILLATORTYPE_HSI;
  RCC_OscInitStruct.HSIState = RCC_HSI_ON;
  RCC_OscInitStruct.HSICalibrationValue = RCC_HSICALIBRATION_DEFAULT;
  RCC_OscInitStruct.PLL.PLLState = RCC_PLL_ON;
  RCC_OscInitStruct.PLL.PLLSource = RCC_PLLSOURCE_HSI_DIV2;
  RCC_OscInitStruct.PLL.PLLMUL = RCC_PLL_MUL16;
  if (HAL_RCC_OscConfig(&RCC_OscInitStruct) != HAL_OK)
  {
    Error_Handler();
  }
  /** Initializes the CPU, AHB and APB buses clocks
  */
  RCC_ClkInitStruct.ClockType = RCC_CLOCKTYPE_HCLK|RCC_CLOCKTYPE_SYSCLK
                              |RCC_CLOCKTYPE_PCLK1|RCC_CLOCKTYPE_PCLK2;
  RCC_ClkInitStruct.SYSCLKSource = RCC_SYSCLKSOURCE_PLLCLK;
  RCC_ClkInitStruct.AHBCLKDivider = RCC_SYSCLK_DIV1;
  RCC_ClkInitStruct.APB1CLKDivider = RCC_HCLK_DIV2;
  RCC_ClkInitStruct.APB2CLKDivider = RCC_HCLK_DIV1;

  if (HAL_RCC_ClockConfig(&RCC_ClkInitStruct, FLASH_LATENCY_2) != HAL_OK)
  {
    Error_Handler();
  }
}

/**
  * @brief USART1 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART1_UART_Init(void)
{

  /* USER CODE BEGIN USART1_Init 0 */

  /* USER CODE END USART1_Init 0 */

  /* USER CODE BEGIN USART1_Init 1 */

  /* USER CODE END USART1_Init 1 */
  huart1.Instance = USART1;
  huart1.Init.BaudRate = 19200;
  huart1.Init.WordLength = UART_WORDLENGTH_8B;
  huart1.Init.StopBits = UART_STOPBITS_1;
  huart1.Init.Parity = UART_PARITY_NONE;
  huart1.Init.Mode = UART_MODE_TX_RX;
  huart1.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart1.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart1) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART1_Init 2 */

  /* USER CODE END USART1_Init 2 */

}

/**
  * @brief USART2 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART2_UART_Init(void)
{

  /* USER CODE BEGIN USART2_Init 0 */

  /* USER CODE END USART2_Init 0 */

  /* USER CODE BEGIN USART2_Init 1 */

  /* USER CODE END USART2_Init 1 */
  huart2.Instance = USART2;
  huart2.Init.BaudRate = 115200;
  huart2.Init.WordLength = UART_WORDLENGTH_8B;
  huart2.Init.StopBits = UART_STOPBITS_1;
  huart2.Init.Parity = UART_PARITY_NONE;
  huart2.Init.Mode = UART_MODE_TX_RX;
  huart2.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart2.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart2) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART2_Init 2 */

  /* USER CODE END USART2_Init 2 */

}

/**
  * @brief USART3 Initialization Function
  * @param None
  * @retval None
  */
static void MX_USART3_UART_Init(void)
{

  /* USER CODE BEGIN USART3_Init 0 */

  /* USER CODE END USART3_Init 0 */

  /* USER CODE BEGIN USART3_Init 1 */

  /* USER CODE END USART3_Init 1 */
  huart3.Instance = USART3;
  huart3.Init.BaudRate = 115200;
  huart3.Init.WordLength = UART_WORDLENGTH_8B;
  huart3.Init.StopBits = UART_STOPBITS_1;
  huart3.Init.Parity = UART_PARITY_NONE;
  huart3.Init.Mode = UART_MODE_TX_RX;
  huart3.Init.HwFlowCtl = UART_HWCONTROL_NONE;
  huart3.Init.OverSampling = UART_OVERSAMPLING_16;
  if (HAL_UART_Init(&huart3) != HAL_OK)
  {
    Error_Handler();
  }
  /* USER CODE BEGIN USART3_Init 2 */

  /* USER CODE END USART3_Init 2 */

}

/**
  * @brief GPIO Initialization Function
  * @param None
  * @retval None
  */
static void MX_GPIO_Init(void)
{
  GPIO_InitTypeDef GPIO_InitStruct = {0};

  /* GPIO Ports Clock Enable */
  __HAL_RCC_GPIOC_CLK_ENABLE();
  __HAL_RCC_GPIOD_CLK_ENABLE();
  __HAL_RCC_GPIOA_CLK_ENABLE();
  __HAL_RCC_GPIOB_CLK_ENABLE();

  /*Configure GPIO pin Output Level */
  HAL_GPIO_WritePin(LD2_GPIO_Port, LD2_Pin, GPIO_PIN_RESET);

  /*Configure GPIO pin : B1_Pin */
  GPIO_InitStruct.Pin = B1_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_IT_RISING;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  HAL_GPIO_Init(B1_GPIO_Port, &GPIO_InitStruct);

  /*Configure GPIO pin : LD2_Pin */
  GPIO_InitStruct.Pin = LD2_Pin;
  GPIO_InitStruct.Mode = GPIO_MODE_OUTPUT_PP;
  GPIO_InitStruct.Pull = GPIO_NOPULL;
  GPIO_InitStruct.Speed = GPIO_SPEED_FREQ_LOW;
  HAL_GPIO_Init(LD2_GPIO_Port, &GPIO_InitStruct);

  /* EXTI interrupt init*/
  HAL_NVIC_SetPriority(EXTI15_10_IRQn, 0, 0);
  HAL_NVIC_EnableIRQ(EXTI15_10_IRQn);

}

/* USER CODE BEGIN 4 */

/* USER CODE END 4 */

/**
  * @brief  This function is executed in case of error occurrence.
  * @retval None
  */
void Error_Handler(void)
{
  /* USER CODE BEGIN Error_Handler_Debug */
  /* User can add his own implementation to report the HAL error return state */
  __disable_irq();
  while (1)
  {
  }
  /* USER CODE END Error_Handler_Debug */
}

#ifdef  USE_FULL_ASSERT
/**
  * @brief  Reports the name of the source file and the source line number
  *         where the assert_param error has occurred.
  * @param  file: pointer to the source file name
  * @param  line: assert_param error line source number
  * @retval None
  */
void assert_failed(uint8_t *file, uint32_t line)
{
  /* USER CODE BEGIN 6 */
  /* User can add his own implementation to report the file name and line number,
     ex: printf("Wrong parameters value: file %s on line %d\r\n", file, line) */
  /* USER CODE END 6 */
}
#endif /* USE_FULL_ASSERT */

