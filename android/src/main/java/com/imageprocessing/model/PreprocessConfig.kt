package com.imageprocessing.model

import com.imageprocessing.config.ColorFormat
import com.imageprocessing.config.Normalization
import com.imageprocessing.config.AlphaHandling
import com.imageprocessing.config.OrientationHandling
import com.imageprocessing.config.OutDType
import com.imageprocessing.config.ResizeStrategy
import com.imageprocessing.config.TensorLayout

data class PreprocessConfig(
  val width: Int?,
  val height: Int?,
  val colorFormat: ColorFormat,
  val normalization: Normalization,
  val mean: FloatArray?,
  val std: FloatArray?,
  val outDType: OutDType,
  val resizeStrategy: ResizeStrategy,
  val tensorLayout: TensorLayout,
  val orientationHandling: OrientationHandling,
  val alphaHandling: AlphaHandling,
  val channelCount: Int,
)
