using Images, ImageView, ImageCore
include("src/SLIC.jl")

input_image = load("lenna.bmp")
#input_image = load("dog.png")
#imshow(input_image)
#mosaicview(input_image)

out_image = slic(input_image, 500, 30, 10)
save("foo.png", out_image)
out_image_1 = slic(input_image, 500, 30, 10, true)
save("bar.png", out_image_1)
