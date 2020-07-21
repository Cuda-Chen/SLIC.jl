using Images

struct Cluster
    l
    a
    b
    x
    y
    index
end

function slic(img, K, M)
    size_tuple = size_spatial(img)
    image_height = size_tuple[1]
    image_width = size_tuple[2] 
end
