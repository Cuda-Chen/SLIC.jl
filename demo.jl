using Images, ImageView, ImageCore

input_image = load("dog.png")
#imshow(input_image)
#mosaicview(input_image)
#save("foo.bmp", input_image)
println(size_spatial(input_image)) # get the size of an image
println(size_spatial(input_image)[1])
println(size_spatial(input_image)[2])
