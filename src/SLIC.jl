using Images

struct Cluster
    l
    a
    b
    x
    y
    index
end

function slic(img, K, M, iterations=10)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
    S = Integer(sqrt((image_height * image_width) / K))
    clusters = Cluster[]
    labels = Dict()
    distance = Matrix(Inf, image_height, image_width)

    # Initialize each cluster
    
end
