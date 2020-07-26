using Images, ImageView, ImageCore
include("src/SLIC.jl")

input_image = load("lenna.bmp")
#input_image = load("dog.png")
#imshow(input_image)
#mosaicview(input_image)
#save("foo.bmp", input_image)
println(size_spatial(input_image)) # get the size of an image
println(size_spatial(input_image)[1])
println(size_spatial(input_image)[2])

out_image = slic(input_image, 400, 30, 1)
save("foo.png", out_image)
