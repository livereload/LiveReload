module ChunkyPNG
  class Canvas

    # The ChunkyPNG::Canvas::Resampling module defines methods to perform image resampling to
    # a {ChunkyPNG::Canvas}.
    #
    # Currently, only the nearest neighbor algorithm is implemented. Bilinear and cubic
    # algorithms may be added later on.
    #
    # @see ChunkyPNG::Canvas
    module Resampling

      # Resamples the canvas.
      # @param [Integer] new_width The width of the resampled canvas.
      # @param [Integer] new_height The height of the resampled canvas.
      # @return [ChunkyPNG::Canvas] A new canvas instance with the resampled pixels.
      def resample_nearest_neighbor!(new_width, new_height)

        width_ratio  = width.to_f / new_width.to_f
        height_ratio = height.to_f / new_height.to_f

        pixels = []
        for y in 1..new_height do
          source_y   = (y - 0.5) * height_ratio + 0.5
          input_y    = source_y.to_i

          for x in 1..new_width do
            source_x = (x - 0.5) * width_ratio + 0.5
            input_x  = source_x.to_i

            pixels << get_pixel([input_x - 1, 0].max, [input_y - 1, 0].max)
          end
        end

        replace_canvas!(new_width.to_i, new_height.to_i, pixels)
      end

      def resample_nearest_neighbor(new_width, new_height)
        dup.resample_nearest_neighbor!(new_width, new_height)
      end

      alias_method :resample, :resample_nearest_neighbor
      alias_method :resize, :resample
    end
  end
end
