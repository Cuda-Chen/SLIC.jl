using Images, ImageView, ImageCore, BenchmarkTools
include("src/SLIC.jl")

input_image = load("lenna.bmp")
#input_image = load("dog.png")
#imshow(input_image)
#mosaicview(input_image)

#@btime out_image = slic($input_image, 100, 10, 10)
#save("foo.png", out_image)
@btime out_image_1 = slic($input_image, 100, 10, 10, true)
#save("bar.png", out_image_1)
